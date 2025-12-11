import click
from langchain_openai import ChatOpenAI
from langchain_anthropic import ChatAnthropic
from langchain_core.prompts import ChatPromptTemplate
from langchain_qdrant import QdrantVectorStore
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams
from langchain_openai import OpenAIEmbeddings
from langchain_community.document_loaders import DirectoryLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from pathlib import Path
import json
import subprocess
import os

K8S_DOCS_PATH = 'k8s-docs'


@click.group()
def cli():
    """LLM vs RAG evaluation CLI for Kubernetes documentation."""
    pass


@cli.group()
def docs():
    """Manage Kubernetes documentation."""
    pass


@docs.command()
@click.option('--docs-path', default=K8S_DOCS_PATH, help='Directory to clone the repository into')
@click.option('--tag', help='Git tag to checkout after cloning')
def get(docs_path, tag):
    """Clone the Kubernetes website repository."""
    repo_url = "https://github.com/kubernetes/website.git"

    try:
        if os.path.exists(docs_path):
            click.echo(f"Directory '{docs_path}' already exists. Skipping clone.")
            if tag:
                click.echo(f"Checking out tag '{tag}'...")
                subprocess.run(['git', '-C', docs_path, 'checkout', f'tags/{tag}'], check=True)
                click.echo(f"✓ Checked out tag '{tag}'")
        else:
            click.echo(f"Cloning {repo_url} into {docs_path}...")
            subprocess.run(['git', 'clone', repo_url, docs_path], check=True)
            click.echo(f"✓ Successfully cloned Kubernetes documentation to {docs_path}")

            if tag:
                click.echo(f"Checking out tag '{tag}'...")
                subprocess.run(['git', '-C', docs_path, 'checkout', f'tags/{tag}'], check=True)
                click.echo(f"✓ Checked out tag '{tag}'")
    except subprocess.CalledProcessError as e:
        click.echo(f"Error: Git operation failed: {e}", err=True)
        raise click.Abort()


@docs.command()
def tags():
    """List available tags from the Kubernetes website repository."""
    repo_url = "https://github.com/kubernetes/website.git"

    click.echo(f"Fetching tags from {repo_url}...")
    try:
        result = subprocess.run(
            ['git', 'ls-remote', '--tags', '--sort=-v:refname', repo_url],
            check=True,
            capture_output=True,
            text=True
        )

        tags = []
        for line in result.stdout.strip().split('\n'):
            if line:
                # Extract tag name from refs/tags/...
                parts = line.split('refs/tags/')
                if len(parts) > 1:
                    tag_name = parts[1].replace('^{}', '')  # Remove ^{} suffix for annotated tags
                    if tag_name not in tags and tag_name.startswith('snapshot-initial-'):  # Filter for release- tags
                        tags.append(tag_name)

        click.echo(f"\nAvailable release tags ({len(tags)} total):")
        for tag in tags[:50]:  # Show first 50 tags
            click.echo(f"  {tag}")

        if len(tags) > 50:
            click.echo(f"\n... and {len(tags) - 50} more tags")
            click.echo("Use 'python evaluation.py docs get --tag <tag-name>' to clone a specific version")

    except subprocess.CalledProcessError as e:
        click.echo(f"Error: Failed to fetch tags: {e}", err=True)
        raise click.Abort()


@cli.command()
@click.option('--docs-path', default=f"{K8S_DOCS_PATH}/content/en/docs/concepts/containers",
              help='Path to K8s documentation directory', type=click.Path())
@click.option('--collection-name', default="k8s_docs", help='Qdrant collection name')
@click.option('--qdrant-url', default="http://localhost:6333", help='Qdrant server URL')
@click.option('--chunk-size', default=1000, help='Text chunk size for splitting')
@click.option('--chunk-overlap', default=100, help='Overlap between chunks')
@click.option('--recreate/--no-recreate', default=True, help='Recreate collection if exists')
def index(docs_path, collection_name, qdrant_url, chunk_size, chunk_overlap, recreate):
    """Index Kubernetes documentation into Qdrant vector store."""
    click.echo(f"Loading documents from {docs_path}...")
    loader = DirectoryLoader(docs_path, glob="**/*.md")
    docs = loader.load()
    click.echo(f"Loaded {len(docs)} documents")

    click.echo(f"Splitting documents (chunk_size={chunk_size}, overlap={chunk_overlap})...")
    splitter = RecursiveCharacterTextSplitter(chunk_size=chunk_size, chunk_overlap=chunk_overlap)
    chunks = splitter.split_documents(docs)
    click.echo(f"Created {len(chunks)} chunks")

    # Initialize Qdrant client
    client = QdrantClient(url=qdrant_url)

    # Create collection
    if recreate:
        try:
            client.delete_collection(collection_name)
            click.echo(f"Deleted existing collection '{collection_name}'")
        except:
            pass

    click.echo(f"Creating collection '{collection_name}'...")
    client.create_collection(
        collection_name=collection_name,
        vectors_config=VectorParams(size=1536, distance=Distance.COSINE)
    )

    # Initialize embeddings and vectorstore
    embeddings = OpenAIEmbeddings()
    vectorstore = QdrantVectorStore(
        client=client,
        collection_name=collection_name,
        embedding=embeddings
    )

    # Add documents to the collection
    click.echo("Adding documents to vector store...")
    vectorstore.add_documents(chunks)
    click.echo(f"✓ Successfully indexed {len(chunks)} chunks into '{collection_name}'")


@cli.command()
@click.option('--collection-name', default="k8s_docs", help='Qdrant collection name')
@click.option('--qdrant-url', default="http://localhost:6333", help='Qdrant server URL')
@click.option('--models', default="gpt-5-nano", help='Comma-separated model names (gpt-5,claude-sonnet,gpt-4o-mini)')
@click.option('--question', '-q', multiple=True, help='Question to evaluate (can be used multiple times)')
@click.option('--questions-file', type=click.Path(exists=True), help='JSON file with list of questions')
@click.option('--retriever-k', default=4, help='Number of documents to retrieve for RAG')
@click.option('--mode', type=click.Choice(['both', 'base', 'rag']), default='both',
              help='Evaluation mode: both (base + RAG), base only, or RAG only')
@click.option('--show-context/--no-show-context', default=False, help='Show retrieved context')
@click.option('--output', default="./evaluation.json", type=click.Path(), help='Save results to JSON file')
def evaluate(collection_name, qdrant_url, models, question, questions_file, retriever_k, mode, show_context, output):
    """Run evaluation comparing pure LLM vs RAG approaches."""

    # Parse models
    model_list = [m.strip() for m in models.split(',')]
    model_map = {}
    for model_name in model_list:
        if model_name == "gpt-5-nano":
            model_map[model_name] = ChatOpenAI(model="gpt-5")
        elif model_name == "claude-sonnet":
            model_map[model_name] = ChatAnthropic(model="claude-sonnet-4-20250514")
        else:
            click.echo(f"Warning: Unknown model '{model_name}', skipping...")

    if not model_map:
        click.echo("Error: No valid models specified", err=True)
        return

    # Parse questions
    questions = list(question) if question else []
    if questions_file:
        with open(questions_file) as f:
            questions.extend(json.load(f))

    if not questions:
        questions = [
            "Why is my pod stuck in CrashLoopBackOff?",
            # "How do I set up a PodDisruptionBudget?",
            # "What's the difference between requests and limits?",
        ]
        click.echo("No questions provided, using default questions...")

    # Setup RAG
    if mode in ['both', 'rag']:
        click.echo(f"Connecting to Qdrant at {qdrant_url}...")
        client = QdrantClient(url=qdrant_url)
        embeddings = OpenAIEmbeddings()
        vectorstore = QdrantVectorStore(
            client=client,
            collection_name=collection_name,
            embedding=embeddings
        )
        retriever = vectorstore.as_retriever(search_kwargs={"k": retriever_k})

    # Setup prompts
    base_prompt = ChatPromptTemplate.from_messages([
        ("system", "You are a Kubernetes expert. Be concise and accurate."),
        ("human", "{question}")
    ])

    rag_prompt = ChatPromptTemplate.from_messages([
        ("system", "You are a Kubernetes expert. Use this context:\n{context}"),
        ("human", "{question}")
    ])

    # Run evaluation
    all_results = {}

    for q in questions:
        click.echo(f"\n{'='*80}")
        click.echo(f"Question: {q}")
        click.echo('='*80)

        results = {}
        context = None
        context_docs_info = None

        # Get context for RAG
        if mode in ['both', 'rag']:
            context_docs = retriever.invoke(q)
            context = "\n\n".join(d.page_content for d in context_docs)
            context_docs_info = [
                {
                    "content": doc.page_content,
                    "metadata": doc.metadata
                }
                for doc in context_docs
            ]

            if show_context:
                click.echo(f"\n[Context Retrieved ({len(context_docs)} docs)]")
                click.echo("-" * 80)
                click.echo(context[:500] + "..." if len(context) > 500 else context)
                click.echo("-" * 80)

        for name, model in model_map.items():
            # Without RAG
            if mode in ['both', 'base']:
                click.echo(f"\n[{name} - Base]")
                chain = base_prompt | model
                response = chain.invoke({"question": q}).content
                results[f"{name}_base"] = {
                    "input": {
                        "question": q,
                        "prompt": base_prompt.format_messages(question=q)[0].content + "\n\n" + base_prompt.format_messages(question=q)[1].content,
                        "system_prompt": base_prompt.format_messages(question=q)[0].content,
                        "human_prompt": base_prompt.format_messages(question=q)[1].content,
                    },
                    "response": response
                }
                click.echo(response)

            # With RAG
            if mode in ['both', 'rag']:
                click.echo(f"\n[{name} - RAG]")
                chain_rag = rag_prompt | model
                response = chain_rag.invoke({
                    "question": q,
                    "context": context
                }).content
                formatted_messages = rag_prompt.format_messages(question=q, context=context)
                results[f"{name}_rag"] = {
                    "input": {
                        "question": q,
                        "context": context,
                        "context_docs": context_docs_info,
                        "prompt": formatted_messages[0].content + "\n\n" + formatted_messages[1].content,
                        "system_prompt": formatted_messages[0].content,
                        "human_prompt": formatted_messages[1].content,
                    },
                    "response": response
                }
                click.echo(response)

        all_results[q] = results

    # Save results if output specified
    if output:
        with open(output, 'w') as f:
            json.dump(all_results, f, indent=2)
        click.echo(f"\n✓ Results saved to {output}")


@cli.command()
@click.option('--docs-path', default="/Users/dev/Documents/proj/dev/agentic-k8s/website/content/en/docs/concepts/workloads",
              help='Path to K8s documentation directory')
@click.option('--collection-name', default="k8s_docs", help='Qdrant collection name')
@click.option('--qdrant-url', default="http://localhost:6333", help='Qdrant server URL')
@click.option('--models', default="gpt-5-nano", help='Comma-separated model names')
@click.option('--question', '-q', multiple=True, help='Question to evaluate')
@click.option('--output', type=click.Path(), help='Save results to JSON file')
def run(docs_path, collection_name, qdrant_url, models, question, output):
    """Index documents and run evaluation in one command."""
    click.echo("Step 1: Indexing documents...")
    ctx = click.get_current_context()
    ctx.invoke(index, docs_path=docs_path, collection_name=collection_name,
               qdrant_url=qdrant_url, chunk_size=1000, chunk_overlap=100, recreate=True)

    click.echo("\n\nStep 2: Running evaluation...")
    ctx.invoke(evaluate, collection_name=collection_name, qdrant_url=qdrant_url,
               models=models, question=question, questions_file=None, retriever_k=4,
               mode='both', show_context=False, output=output)


if __name__ == '__main__':
    cli()