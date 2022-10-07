$NuGetBase = '/NuGet'
Add-Type -Path $NuGetBase/Newtonsoft.Json/lib/netstandard2.0/Newtonsoft.Json.dll
Add-Type -Path $NuGetBase/CassandraCSharpDriver/lib/netstandard2.0/Cassandra.dll
$clusterBuilder = [Cassandra.Cluster]::Builder()
$clusterBuilder = $clusterBuilder.AddContactPoints("Cassandra-1")
$clusterBuilder.Build()

# Failes with:
# MethodInvocationException: Exception calling "Build" with "0" argument(s): "The type initializer for 'Cassandra.AtomicMonotonicTimestampGenerator' threw an exception."