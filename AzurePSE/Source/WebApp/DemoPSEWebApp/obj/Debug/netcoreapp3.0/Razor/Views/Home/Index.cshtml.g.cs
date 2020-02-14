#pragma checksum "C:\VSCode\LaglerGruenerGitHub\AzurePSScripts\AzurePSE\Source\WebApp\DemoPSEWebApp\Views\Home\Index.cshtml" "{ff1816ec-aa5e-4d10-87f7-6f4963833460}" "d61d770b751a6643a332521d98473b41013ea324"
// <auto-generated/>
#pragma warning disable 1591
[assembly: global::Microsoft.AspNetCore.Razor.Hosting.RazorCompiledItemAttribute(typeof(AspNetCore.Views_Home_Index), @"mvc.1.0.view", @"/Views/Home/Index.cshtml")]
namespace AspNetCore
{
    #line hidden
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Threading.Tasks;
    using Microsoft.AspNetCore.Mvc;
    using Microsoft.AspNetCore.Mvc.Rendering;
    using Microsoft.AspNetCore.Mvc.ViewFeatures;
#nullable restore
#line 1 "C:\VSCode\LaglerGruenerGitHub\AzurePSScripts\AzurePSE\Source\WebApp\DemoPSEWebApp\Views\_ViewImports.cshtml"
using WebApplication2;

#line default
#line hidden
#nullable disable
#nullable restore
#line 2 "C:\VSCode\LaglerGruenerGitHub\AzurePSScripts\AzurePSE\Source\WebApp\DemoPSEWebApp\Views\_ViewImports.cshtml"
using WebApplication2.Models;

#line default
#line hidden
#nullable disable
    [global::Microsoft.AspNetCore.Razor.Hosting.RazorSourceChecksumAttribute(@"SHA1", @"d61d770b751a6643a332521d98473b41013ea324", @"/Views/Home/Index.cshtml")]
    [global::Microsoft.AspNetCore.Razor.Hosting.RazorSourceChecksumAttribute(@"SHA1", @"6b36aee4455a440795f240a74431c307640c545e", @"/Views/_ViewImports.cshtml")]
    public class Views_Home_Index : global::Microsoft.AspNetCore.Mvc.Razor.RazorPage<dynamic>
    {
        #pragma warning disable 1998
        public async override global::System.Threading.Tasks.Task ExecuteAsync()
        {
#nullable restore
#line 1 "C:\VSCode\LaglerGruenerGitHub\AzurePSScripts\AzurePSE\Source\WebApp\DemoPSEWebApp\Views\Home\Index.cshtml"
  
    ViewData["Title"] = "Demo WebApp PSE Endpoint";

#line default
#line hidden
#nullable disable
            WriteLiteral(@"
    <div class=""text-center"">
        <h1 class=""display-4"">Welcome to the private pse demo Website</h1>
        <p>Learn more about PSE at <a href=""https://www.cloudblogger.at/2019/12/02/azure-service-endpoint-architecture/"" target=""_blank"">my Blog.</a>.</p>        
    </div>
    <div>
        <h4>Connect to Azure KeyVault and get secred</h4>
        <b>State:</b> ");
#nullable restore
#line 11 "C:\VSCode\LaglerGruenerGitHub\AzurePSScripts\AzurePSE\Source\WebApp\DemoPSEWebApp\Views\Home\Index.cshtml"
                 Write(ViewBag.KeyVaultConnectionState);

#line default
#line hidden
#nullable disable
            WriteLiteral("\r\n        <hr />\r\n        <h4>Connect to database</h4>\r\n        <b>State:</b> ");
#nullable restore
#line 14 "C:\VSCode\LaglerGruenerGitHub\AzurePSScripts\AzurePSE\Source\WebApp\DemoPSEWebApp\Views\Home\Index.cshtml"
                 Write(ViewBag.SQLConnectionState);

#line default
#line hidden
#nullable disable
            WriteLiteral("\r\n        <br />\r\n        <b>Total SQL entries:</b> ");
#nullable restore
#line 16 "C:\VSCode\LaglerGruenerGitHub\AzurePSScripts\AzurePSE\Source\WebApp\DemoPSEWebApp\Views\Home\Index.cshtml"
                             Write(ViewBag.SQLEntriesreturn);

#line default
#line hidden
#nullable disable
            WriteLiteral("\r\n        <hr />\r\n        <h4>General state</h4>\r\n        <b>Error:</b>  ");
#nullable restore
#line 19 "C:\VSCode\LaglerGruenerGitHub\AzurePSScripts\AzurePSE\Source\WebApp\DemoPSEWebApp\Views\Home\Index.cshtml"
                  Write(ViewBag.Error);

#line default
#line hidden
#nullable disable
            WriteLiteral("\r\n        <br />\r\n        <b>Error Message:</b> ");
#nullable restore
#line 21 "C:\VSCode\LaglerGruenerGitHub\AzurePSScripts\AzurePSE\Source\WebApp\DemoPSEWebApp\Views\Home\Index.cshtml"
                         Write(ViewBag.ErrorMSG);

#line default
#line hidden
#nullable disable
            WriteLiteral("\r\n    </div>\r\n");
        }
        #pragma warning restore 1998
        [global::Microsoft.AspNetCore.Mvc.Razor.Internal.RazorInjectAttribute]
        public global::Microsoft.AspNetCore.Mvc.ViewFeatures.IModelExpressionProvider ModelExpressionProvider { get; private set; }
        [global::Microsoft.AspNetCore.Mvc.Razor.Internal.RazorInjectAttribute]
        public global::Microsoft.AspNetCore.Mvc.IUrlHelper Url { get; private set; }
        [global::Microsoft.AspNetCore.Mvc.Razor.Internal.RazorInjectAttribute]
        public global::Microsoft.AspNetCore.Mvc.IViewComponentHelper Component { get; private set; }
        [global::Microsoft.AspNetCore.Mvc.Razor.Internal.RazorInjectAttribute]
        public global::Microsoft.AspNetCore.Mvc.Rendering.IJsonHelper Json { get; private set; }
        [global::Microsoft.AspNetCore.Mvc.Razor.Internal.RazorInjectAttribute]
        public global::Microsoft.AspNetCore.Mvc.Rendering.IHtmlHelper<dynamic> Html { get; private set; }
    }
}
#pragma warning restore 1591