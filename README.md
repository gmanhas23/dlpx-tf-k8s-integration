# Terrafactory
### [Work in Progress]
Where the transient magic of the Delphix Kubernetes Driver synergizes with the wizardry of the Delphix Terraform provider to go where no man has ever gone before.

Terraform provider can be used to create the underlying infrastructure ( both non-Kubernetes and Kubernetes clusters) needed for the Delphix Kubernetes driver implementation.
This includes creating the Delphix engine, virtual machines(non-Kubernetes host environments), cloud-native kubernetes clusters, dsources/VDBs, hook operations etc.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

We require the following to get started:
- Delphix Control Tower(DCT) instance
- Delphix Continuous Data Engine, v15.0.0+
- Kubernetes v1.21+
- Any RHEL 7.X host environment to act as a staging host
- Delphix Kubernetes Driver v1.0.0 and Delphix Kubernetes Plugin (delphix-k8s-plugin)
- Terraform provider for Delphix, v3.1.0


## Deployment

```
terraform apply
```

## Contributing

Please read [CONTRIBUTING.md](https://github.com/delphix/.github/blob/master/CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags). 
