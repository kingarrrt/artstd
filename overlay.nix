final: prev:
let

  inherit (final.lib) getExe' optionalString hiPrio;
  inherit (final.writers) writeBashBin;

  execDefault = exe: ''exec -a "$0" ${exe} "$@"'';

in
{

  writers = prev.writers // {
    writeBashBin =
      name: script:
      prev.writers.writeBashBin name ''
        set -euo pipefail
        ${script}
      '';
  };

  script =
    name: content:
    # using writeBashBin so we get a proper basename under logtrace
    getExe' (writeBashBin name content) name;

  scriptFile =
    name: src: attrs:
    final.script name ". ${final.replaceVars src attrs}";

  scriptWrapper =
    {
      package,
      name ? package.meta.mainProgram,
      override ? name,
      script ? "",
      exe ? getExe' package name,
      exec ? execDefault,
    }:
    writeBashBin override ''
      ${script}
      ${optionalString (exec != null) (exec exe)}
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
          (hiPrio (
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
