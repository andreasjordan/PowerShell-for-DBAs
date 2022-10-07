How to use PowerShell as an Apache Cassandra administrator.

## Install the server

You can use any existing server in your environment. If you want to setup a server just for tests, you find some recommendations in this section.

### Docker

I use the image [cassandra:latest](https://hub.docker.com/_/cassandra) for my labs. See my install script [SetupServerWithDocker.ps1](../PowerShell/SetupServerWithDocker.ps1) in the PowerShell folder for details.


## Install the client

This is work in progress and help is needed.

I want to use the [DataStax C# Driver for Apache Cassandra](https://docs.datastax.com/en/developer/csharp-driver/3.16/) ([GitHub](https://github.com/datastax/csharp-driver) / [NuGet](https://www.nuget.org/packages/CassandraCSharpDriver/)).

And I think I have downloaded the needed dependencies, but this code:

```
$NuGetBase = '/NuGet'
Add-Type -Path $NuGetBase/Newtonsoft.Json/lib/netstandard2.0/Newtonsoft.Json.dll
Add-Type -Path $NuGetBase/CassandraCSharpDriver/lib/netstandard2.0/Cassandra.dll
$clusterBuilder = [Cassandra.Cluster]::Builder()
$clusterBuilder = $clusterBuilder.AddContactPoints("Cassandra-1")
$clusterBuilder.Build()
```

fails with:

```
MethodInvocationException: Exception calling "Build" with "0" argument(s): "The type initializer for 'Cassandra.AtomicMonotonicTimestampGenerator' threw an exception."
```

It also fails with the same message on PowerShell 5.1 using the net452 library.

