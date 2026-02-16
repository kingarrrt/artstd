final: _prev:
let
  execDefault = exe: ''exec -a "$0" ${exe} "$@"'';
  inherit (final) lib;
in
{

  script =
    name: content:
    # using writeBashBin so we get a proper basename under logtrace
    lib.getExe' (final.writers.writeBashBin name ''
      . ${lib.getExe' final.artstd "shlib"}
      ${content}
    '') name;

  scriptFile =
    name: src: attrs:
    final.script name ". ${final.replaceVars src attrs}";

  scriptWrapper =
    {
      package,
      name ? package.meta.mainProgram,
      override ? name,
      script ? "",
      exe ? final.lib.getExe' package name,
      exec ? execDefault,
    }:
    final.writers.writeBashBin override ''
      . ${lib.getExe' final.artstd "shlib"}
      ${script}
      ${lib.optionalString (exec != null) (exec exe)}
    '';

  scriptWrapperEnv =
    {
      package,
      name ? package.meta.mainProgram,
      override ? name,
      script ? "",
      exec ? execDefault,
      ...
    }@attrs:
    # use buildEnv cos we want the real package contents for compdef, man, etc.
    final.buildEnv (
      {
        name = "${package.name}-wrapper-env";
        meta.mainProgram = name;
        paths = attrs.paths or [ ] ++ [
          (lib.hiPrio (
            final.scriptWrapper {
              inherit
                package
                name
                override
                script
                exec
                ;
            }
          ))
          package
        ];
      }
      // builtins.removeAttrs attrs [
        "package"
        "name"
        "override"
        "script"
        "exec"
        "paths"
      ]
    );

}
