using System.Diagnostics.CodeAnalysis;
using System.IO.Compression;
using System.Text.Json;
using CripUpdater.GitHub;
using RestSharp;

namespace CripUpdater;

internal static class Program
{
    static readonly JsonSerializerOptions Options = new()
    {
        Converters =
        {
            StateConverter.Singleton
        }
    };
    [RequiresDynamicCode("Calls System.Text.Json.JsonSerializer.Deserialize<TValue>(String, JsonSerializerOptions)")]
    [RequiresUnreferencedCode("Calls System.Text.Json.JsonSerializer.Deserialize<TValue>(String, JsonSerializerOptions)")]
    private static async Task Main(string[] args)
    {
        Console.WriteLine("Starting CripUpdater...");
        var client = new RestClient("https://api.github.com");
        var request = new RestRequest("repos/Hakky54/certificate-ripper/releases/latest");
        request.AddHeader("Accept", "application/vnd.github+json");

        var response = client.Execute(request);
        if (response.Content is not { } jsonContent)
            throw new JsonException("JSON was empty");
        var latest = JsonSerializer.Deserialize<LatestRelease>(jsonContent, Options);
        if (latest is null)
            throw new JsonException("JSON was null");
        if(latest.Assets is null) throw new InvalidOperationException("No assets found");
        if (latest.Assets.FirstOrDefault(asset=> asset.Name?.Contains("windows-amd64") == true) is not {} assetWin)
        {
            throw new InvalidOperationException("No windows-amd64 asset found");
        }
        if(assetWin.Name is null || assetWin.BrowserDownloadUrl is null) throw new InvalidOperationException("No download URL found");
        var outZip = Path.Combine(Path.GetTempPath(), assetWin.Name);
        var downloadRequest = new RestRequest(assetWin.BrowserDownloadUrl);
        Console.WriteLine($"Downloading '{assetWin.Name}' to '{outZip}'");
        if (await client.DownloadDataAsync(downloadRequest) is { } rawBytes)
        {
            await using FileStream outFileStream = new(outZip,FileMode.OpenOrCreate,FileAccess.Write,FileShare.Write,rawBytes.Length,FileOptions.Asynchronous);
            await outFileStream.WriteAsync(rawBytes);
        }
        var destinationPath = GetDestinationPath(args);
        
        Console.WriteLine($"Extracting '{outZip}' to '{destinationPath}'");
        ZipFile.ExtractToDirectory(outZip, destinationPath, true);
        Console.WriteLine("Done!");
    }
    private static string GetDestinationPath(string[] args)
{
    if (args.Length > 0 && !string.IsNullOrEmpty(args[0]))
    {
        return args[0];
    }
    else
    {
        return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Programs", "certificate-ripper");
    }
}
}