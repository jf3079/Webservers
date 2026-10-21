output "private_key" {
  value     = tls_private_key.key_pair2.private_key_pem
  sensitive = true
}