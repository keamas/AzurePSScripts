using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.KeyVault;
using Microsoft.Azure.Services.AppAuthentication;
using Microsoft.Extensions.Configuration.AzureKeyVault;
using Microsoft.Extensions.Logging;
using WebApplication2.Models;

namespace WebApplication2.Controllers
{
    public class HomeController : Controller
    {
        private readonly ILogger<HomeController> _logger;

        public HomeController(ILogger<HomeController> logger)
        {
            _logger = logger;
        }
        
        public async System.Threading.Tasks.Task<ActionResult> Index()
        {
            AzureServiceTokenProvider azureServiceTokenProvider = new AzureServiceTokenProvider();
            ViewBag.KeyVaultConnectionState = "Cannot get secred";
            ViewBag.SQLEntriesreturn = "null";
            ViewBag.SQLConnectionState = "none";
            ViewBag.Error = "none";
            ViewBag.ErrorMSG = "";

            try
            {
                var keyVaultClient = new KeyVaultClient(
                    new KeyVaultClient.AuthenticationCallback(azureServiceTokenProvider.KeyVaultTokenCallback));

                var secret = await keyVaultClient.GetSecretAsync("https://laglerh-testkeyvault.vault.azure.net/secrets/dbconnection")
                    .ConfigureAwait(false);                

                SqlConnectionStringBuilder builder = new SqlConnectionStringBuilder();

                string connectionstring = secret.Value;
                ViewBag.KeyVaultConnectionState = "Success";

                using (SqlConnection connection = new SqlConnection(connectionstring))
                {
                    try
                    {
                        connection.Open();
                        ViewBag.SQLConnectionState = "Success";

                        string sql = "select count(*) from table_name";

                        using (SqlCommand command = new SqlCommand(sql, connection))
                        {
                            ViewBag.SQLEntriesreturn = command.ExecuteScalar();
                        }
                    }
                    catch (Exception exp)
                    {
                        ViewBag.Error = "Error";
                        ViewBag.ErrorMSG = $"Cannot connect to Database: {exp.Message}";
                    }

                    connection.Close();
                }

            }
            catch (Exception exp)
            {
                ViewBag.Error = "Error";
                ViewBag.ErrorMSG = $"Something went wrong: {exp.Message}";                
            }

            return View();
        }       

        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }
    }
}
