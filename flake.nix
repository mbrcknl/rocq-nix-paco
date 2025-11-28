{
  description = "Coq library implementing parameterized coinduction";

  inputs = {
    rocq-nix.url = "github:mbrcknl/rocq-nix";

    paco.url = "github:snu-sf/paco";
    paco.flake = false;
  };

  outputs =
    inputs:
    inputs.rocq-nix.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        treefmt.programs.nixfmt.enable = true;

        rocq.dev.sources."paco".input = "paco";

        rocq.versions.default = "9.1.0";
        rocq.versions.supported = {
          "9.0.1" = true;
          "9.1.0" = true;
        };

        rocq.versions.foreach =
          { pkgs, rocq, ... }:
          let
            inherit (rocq) coq rocqPackages;
            inherit (rocqPackages) stdlib;

            paco = pkgs.stdenv.mkDerivation {
              name = "rocq${coq.coq-version}-paco";
              src = inputs.paco;
              buildInputs = [
                coq
                stdlib
              ];
              enableParallelBuilding = true;
              preBuild = "cd src";
              installPhase = ''
                COQLIBINSTALL="$out/lib/coq/${coq.coq-version}/user-contrib";
                (
                  mkdir -p "$COQLIBINSTALL/Paco"
                  shopt -s globstar
                  vo_files=(**/*.vo)
                  tar -c -f- \
                    "''${vo_files[@]/.vo/.glob}" \
                    "''${vo_files[@]/.vo/.v}" \
                    "''${vo_files[@]}" \
                    | tar -x -f- -C "$COQLIBINSTALL/Paco"
                )
              '';
              meta = {
                inherit (coq.meta) platforms;
                homepage = "https://plv.mpi-sws.org/paco/";
                description = "Coq library implementing parameterized coinduction";
                license = lib.licenses.bsd3;
              };
            };
          in
          {
            packages = { inherit paco; };
            dev.env.lib = [ stdlib ];
          };
      }
    );
}
