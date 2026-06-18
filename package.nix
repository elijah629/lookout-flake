{
  lib,
  rustPlatform,
  fetchNpmDeps,
  npmHooks,
  nodejs,
  pkg-config,
  copyDesktopItems,
  makeDesktopItem,
  wrapGAppsHook4,
  makeWrapper,
  cairo,
  gdk-pixbuf,
  glib,
  gtk3,
  harfbuzz,
  libayatana-appindicator,
  libdrm,
  libgbm,
  librsvg,
  libsoup_3,
  libxkbcommon,
  openssl,
  pango,
  pipewire,
  webkitgtk_4_1,
  xdg-utils,
  xdotool,
  libx11,
  libxcb,
  libxrandr,
  libxshmfence,
  gst_all_1,
  src,
}:

let
  tauriConfig = builtins.fromJSON (builtins.readFile "${src}/clients/desktop/src-tauri/tauri.conf.json");
  version = tauriConfig.version;
  pname = "lookout";
  npmDepsHash = "sha256-z+KldbcpgtkwI+UdmGU9/jjklnYOt49Yi2VCM/sFltg=";
  npmDeps = fetchNpmDeps {
    inherit src;
    hash = npmDepsHash;
  };

  gstLibs = with gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
    gst-plugins-ugly
  ];

  runtimeLibs = [
    cairo
    gdk-pixbuf
    glib
    gtk3
    harfbuzz
    libayatana-appindicator
    libdrm
    libgbm
    librsvg
    libsoup_3
    libxkbcommon
    openssl
    pango
    pipewire
    webkitgtk_4_1
    xdotool
    libx11
    libxcb
    libxrandr
    libxshmfence
  ] ++ gstLibs;
in
rustPlatform.buildRustPackage {
  inherit pname version src;

  cargoRoot = "clients/desktop/src-tauri";
  cargoHash = "sha256-8VJZ1M6zyMsghfiZQfVWtHwblJnE6zFhylDvPFbPGsc=";

  inherit npmDeps;
  npmRoot = ".";

  nativeBuildInputs = [
    npmHooks.npmConfigHook
    nodejs
    pkg-config
    rustPlatform.bindgenHook
    copyDesktopItems
    makeWrapper
    wrapGAppsHook4
  ];

  buildInputs = runtimeLibs;

  doCheck = false;

  preBuild = ''
    npm run build -w packages/shared
    npm run build -w clients/react
    npm run build -w clients/desktop
  '';

  buildPhase = ''
    runHook preBuild

    cargo build \
      --release \
      --locked \
      --manifest-path clients/desktop/src-tauri/Cargo.toml

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 clients/desktop/src-tauri/target/release/lookout-desktop $out/bin/lookout
    install -Dm644 clients/desktop/src-tauri/icons/icon.png \
      $out/share/icons/hicolor/512x512/apps/lookout.png

    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/bin/lookout \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs} \
      --prefix PATH : ${lib.makeBinPath [ xdg-utils ]}
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "lookout";
      desktopName = "Lookout";
      genericName = "Time Tracker";
      exec = "lookout";
      icon = "lookout";
      comment = "Simple time-tracking via periodic screenshots";
      categories = [
        "Office"
        "Utility"
      ];
      mimeTypes = [ "x-scheme-handler/lookout" ];
    })
  ];

  passthru = {
    inherit npmDeps;
  };

  meta = {
    description = "Simple time-tracking via periodic screenshots as a service";
    homepage = "https://github.com/hackclub/lookout";
    license = lib.licenses.agpl3Plus;
    mainProgram = "lookout";
    platforms = [ "x86_64-linux" ];
  };
}
