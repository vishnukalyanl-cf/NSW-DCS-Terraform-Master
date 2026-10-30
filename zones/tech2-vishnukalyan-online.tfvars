zone_id   = "2e24638974e7cc068cb089e9a74f663b"
zone_name = "tech2.vishnukalyan.online"


dns_records = {
  tf_test_a = {
    name    = "tf"
    type    = "A"
    content = "20.88.188.200"
    proxied = true
  }

  tf_test_b = {
    name    = "tfftest"
    type    = "A"
    content = "20.88.188.200"
    proxied = true
  }
}