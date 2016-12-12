defmodule Nerves.Package.Artifact do
  @moduledoc """
  Package artifacts are the product of compiling a package with a
  specific toolchain.

  """
  @base_dir Path.expand("~/.nerves/artifacts")

  @doc """
  Get the artifact name

  Requires the package and toolchain package to be supplied
  """
  @spec name(Nerves.Package.t, Nerves.Package.t) :: String.t
  def name(pkg, toolchain) do
    target_tuple =
      case pkg.type do
        :toolchain ->
          Nerves.Env.host_platform <> "-" <>
          Nerves.Env.host_arch
        _ ->
        toolchain.config[:target_tuple]
        |> to_string
      end
    "#{pkg.app}-#{pkg.version}.#{target_tuple}"
  end

  @doc """
  Get the base dir for where an artifact for a package should be stored.

  If a package is pulled in from hex, the base dir for an artifact will point
  to the NERVES_ARTIFACT_DIR or if undefined, `~/.nerves/artifacts`

  Packages which were obtained through other Mix SCM's such as path will
  have a base_dir local to the package path
  """
  @spec base_dir(Nerves.Package.t) :: String.t
  def base_dir(pkg) do
    case pkg.dep do
      local when local in [:path, :project] ->
        Nerves.Utils.build_path
        |> Path.join("artifacts")
      _ ->
        System.get_env("NERVES_ARTIFACTS_DIR") || @base_dir
    end

  end

  @doc """
  The full path to the artifact
  """
  @spec dir(Nerves.Package.t, Nerves.Package.t) :: String.t
  def dir(pkg, toolchain) do
    base_dir(pkg)
    |> Path.join(name(pkg, toolchain))
    |> protocol_vsn(pkg)
  end

  @doc """
  Determines if an artifact exists at its artifact dir.
  """
  @spec exists?(Nerves.Package.t, Nerves.Package.t) :: boolean
  def exists?(pkg, toolchain) do
    dir(pkg, toolchain)
    |> File.dir?
  end

  @doc """
  Determines the extension for an artifact based off its type.
  Toolchains use xz compression
  """
  @spec ext(Nerves.Package.t) :: String.t
  def ext(%{type: :toolchain}), do: "tar.xz"
  def ext(_), do: "tar.gz"

  defp protocol_vsn(dir, pkg) do
    if pkg.compiler == :nerves_package do
      dir
    else
      build_path =
        Mix.Project.build_path
        |> Path.join("nerves")
        |> Path.expand
        case pkg.type do
        :toolchain ->
          Path.join(build_path, "toolchain")
        :system ->
          Path.join(build_path, "system")
        type -> Mix.raise "Cannot determine artifact path for #{type}"
      end
    end
  end
end
