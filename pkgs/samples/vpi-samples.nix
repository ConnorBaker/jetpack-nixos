{ cmake
, cudaPackages
, debs
, dpkg
, lib
, opencv
, stdenv
}:
let
  inherit (cudaPackages)
    cuda_cudart
    cuda_nvcc
    vpi
    ;

  vpiMajor = lib.versions.major vpi.version;
in
stdenv.mkDerivation {
  __structuredAttrs = true;
  strictDeps = true;

  pname = "vpi-samples";
  inherit (debs.common."vpi${vpiMajor}-samples") src version;

  unpackCmd = "dpkg -x $src source";
  sourceRoot = "source/opt/nvidia/vpi${vpiMajor}/samples";

  nativeBuildInputs = [ cmake cuda_nvcc dpkg ];
  buildInputs = [ cuda_cudart opencv vpi ];

  configurePhase = ''
    runHook preBuild

    for dirname in $(find . -type d | sort); do
      if [[ -e "$dirname/CMakeLists.txt" ]]; then
        echo "Configuring $dirname"
        pushd $dirname
        cmake .
        popd 2>/dev/null
      fi
    done

    runHook postBuild
  '';

  buildPhase = ''
    runHook preBuild

    for dirname in $(find . -type d | sort); do
      if [[ -e "$dirname/CMakeLists.txt" ]]; then
        echo "Building $dirname"
        pushd $dirname
        make $buildFlags
        popd 2>/dev/null
      fi
    done

    runHook postBuild
  '';

  enableParallelBuilding = true;

  installPhase = ''
    runHook preInstall

    install -Dm 755 -t $out/bin $(find . -type f -maxdepth 2 -perm 755)

    runHook postInstall
  '';
}
