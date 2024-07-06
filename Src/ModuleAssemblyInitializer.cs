
using System;
using System.IO;
using System.Management.Automation;
using System.Reflection;

namespace Ldbc;

public class ModuleAssemblyInitializer : IModuleAssemblyInitializer
{
	//! may be called twice, so use the static constructor
	public void OnImport()
	{
	}

	static ModuleAssemblyInitializer()
	{
		AppDomain.CurrentDomain.AssemblyResolve += AssemblyResolve;
	}

	// Workaround for Desktop
	static Assembly AssemblyResolve(object sender, ResolveEventArgs args)
	{
		if (args.Name.StartsWith("System.Buffers"))
		{
			var root = Path.GetDirectoryName(typeof(ModuleAssemblyInitializer).Assembly.Location);
			var path = $"{root}/System.Buffers.dll";
			var assembly = Assembly.LoadFrom(path);
			return assembly;
		}
		return null;
	}
}
