# Tailscale Documentation

## What is Tailscale?

Tailscale is a secure networking solution that creates a mesh VPN between your devices. It allows you to securely connect to your machines from anywhere without exposing services to the public internet. Key features include:

- **End-to-end encryption** - All connections between nodes are encrypted
- **Zero-config networking** - Automatically handles NAT traversal
- **MagicDNS** - Automatically assigns DNS names to devices in your network
- **Tailscale SSH** - Secure SSH access through your tailnet without exposing port 22
- **HTTPS certificates** - Automatic TLS certificates for your tailnet services

## Installing Tailscale on Windows

1. [Download](https://tailscale.com/download/windows) the latest `.exe` installer. You can use the same `.exe` installer on both 32- and 64-bit Windows; it will install the right version for your system automatically.

2. Run the installer. After installation, a new Tailscale icon will appear in your system tray. If it is not visible, select the up arrow to find it in the system tray overflow area.

3. Right-click the Tailscale icon to expose configuration options and status messages.

4. Under your account, select **Log in** to launch a browser window, and authenticate using your SSO identity provider.

## Installing Tailscale on Linux

For distributions with a package manager (apt, yum, zypper):

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

After installation completes, start the Tailscale client:

```bash
sudo tailscale up
```

The output will display a URL that you can use to authenticate to your Tailscale network (known as a tailnet). After you authenticate, check the Machines page of the admin console to confirm the device appears in your tailnet.

### Starting the Daemon

```bash
sudo tailscaled --state=tailscaled.state
```

If you want to configure systemd to run tailscaled automatically, a service configuration is available in the `systemd/` subdirectory of the unpacked archive.

## Verifying the Installation

To display the Tailscale IPv4 and IPv6 addresses for your device:

```bash
tailscale ip
```

Check the connection status:

```bash
tailscale status
```

## Disable Key Expiry

Devices in a tailnet periodically re-authenticate to stay secure through device key expiry. For devices that should remain continuously connected (servers, Raspberry Pis, media centers, smart home hubs, Docker hosts, NAS devices), you can disable key expiry.

To disable key expiry for a device:
1. Go to the Machines page of the admin console
2. Select the ellipsis icon next to the device
3. Select **Disable key expiry**

> **Security Warning**: Disabling key expiry reduces security and can expose your network if the device or key is compromised. Only do this for trusted devices and revoke the key immediately if the device is lost or replaced.

If your device's key is already expired, you can force re-authentication:

```bash
sudo tailscale up --force-reauth
```

## Using Tailscale SSH

Tailscale SSH lets you manage SSH access to your machine without exposing SSH to the public internet.

### Enable Tailscale SSH

```bash
tailscale set --ssh
```

### Configure Access Controls

Open the [Access controls](https://login.tailscale.com/admin/acls) page of the Tailscale admin console and add the following to your tailnet policy file:

**Network connectivity:**
```json
"grants": [
  {
    "src": ["<jimamuto.github>"],
    "dst": ["<100.74.189.73>"],
    "ip": ["22"]
  }
]
```

**SSH access:**
```json
"ssh": [
  { "action": "accept",
    "src": ["jimamuto.github"],
    "dst": ["autogroup:self"],
    "users": ["root","autogroup:nonroot", "jimoney"]
  }
],
```

### Connect via SSH

```bash
ssh jimoney@100.74.189.73
```

You can also use the MagicDNS hostname of the machine.

## Enabling HTTPS

Connections between Tailscale nodes are secured with end-to-end encryption. However, browsers and tools may warn about HTTP URLs. To protect services with HTTPS, you need a TLS certificate from a public Certificate Authority.

### Configure HTTPS

1. Open the DNS page of the admin console
2. Enable MagicDNS if not already enabled
3. Under HTTPS Certificates, select **Enable HTTPS**
4. Acknowledge that your machine names and tailnet DNS name will be published on a public ledger
5. Run `tailscale cert` on each machine to obtain a certificate

> **Note**: Although the certificate domain obscures the owner of the tailnet, machine names are still published in the public ledger. Do not enable HTTPS if any machine names contain sensitive information.

### Certificate Renewal

Let's Encrypt certificates have a 90-day expiry. When using `tailscale cert`, you are responsible for renewal as the daemon doesn't know where to place renewed certificates.

For automatic renewal, consider using the Caddy integration.

### Disable HTTPS

1. Open the DNS page of the admin console
2. Under HTTPS Certificates, select **Disable HTTPS**

> **Warning**: This will break all links and connections that relied on HTTPS. Certificates are not revoked so you can re-enable if needed.

### Check Certificate Status

In the admin console:
1. Open the Machines page
2. Find the machine
3. Check the TLS certificate section

**Possible statuses:**
- Valid
- Invalid
- Certificate expired
- No certificate found
- Upgrade client to check status

> Note: If a machine is offline, Tailscale cannot report its certificate status. The machine must be running Tailscale v1.56 or later.
