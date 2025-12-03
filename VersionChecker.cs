using System.Diagnostics;
using System.Text.RegularExpressions;

namespace CripUpdater
{
    internal static partial class VersionChecker
    {
        internal static async Task<string?> GetInstalledVersionAsync(string exePath)
        {
            var psi = new ProcessStartInfo
            {
                FileName = exePath,
                Arguments = "--version",
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            using var process = Process.Start(psi);
            if (process == null) return null;

            string output = await process.StandardOutput.ReadToEndAsync();
            await process.WaitForExitAsync();

            // Example output: "Certificate Ripper v2.5.0"
            var match = VersionPattern().Match(output);
            return match.Success ? match.Groups[1].Value : null;
        }

        internal static bool NeedsUpdate(string? installedVersion, string latestVersionTag)
        {
            if (installedVersion is null) return true;

            // Strip leading "v" from GitHub tag
            var latestVersion = latestVersionTag.TrimStart('v');

            // Compare as Version objects
            if (Version.TryParse(installedVersion, out var installed) &&
                Version.TryParse(latestVersion, out var latest))
            {
                return latest > installed;
            }

            // Fallback: string comparison
            return !string.Equals(installedVersion, latestVersion, StringComparison.OrdinalIgnoreCase);
        }

        [GeneratedRegex(@"Certificate Ripper.*?([\d\.]+)")]
        private static partial Regex VersionPattern();
    }
}