# Creating my own agents

I copied the manifest of one of the pre-installed agents and modfied it to get to simple agents:

* [Installer Agent](./installer-agent.yml) - an agent that does nothing but install k8s resources
* [Uninstaller Agent](./uninstaller-agent.yml) - an agent that does nothing but uninstall k8s resources

With kagent running in the cluster you can just apply these manifests and play with the agent in the ui (`kagent dashbaord`).

## For local dev

[Local dev docs](https://kagent.dev/docs/kagent/getting-started/local-development)

```bash
kagent build
kagent run
```
