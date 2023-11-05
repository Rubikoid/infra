{
  virtualisation.oci-containers.containers =
    let
      memos_version = "0.16.1";
      memos_data_folder = "/backup-drive/data/memos";
      memos_port = "5230";
      memos_host = "127.0.0.1";
    in
    {
      memos = {
        image = "ghcr.io/usememos/memos:${memos_version}";

        ports = [
          "${memos_host}:${memos_port}:5230"
        ];

        volumes = [
          "${memos_data_folder}:/var/opt/memos"
        ];
      };
    };
}
