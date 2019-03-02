workflow "Publish mod to portal" {
  on = "push"
  resolves = ["shanemadden/factorio-mod-portal-publish@master"]
}

action "shanemadden/factorio-mod-portal-publish@master" {
  uses = "shanemadden/factorio-mod-portal-publish@master"
  secrets = ["FACTORIO_USER", "FACTORIO_PASSWORD"]
}
