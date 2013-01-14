﻿using System;
using System.Net;
using System.Web;
using Mindscape.Raygun4Net.Messages;

using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Mindscape.Raygun4Net
{
  public abstract class RaygunClient
  {
    private readonly string _apiKey;

    public RaygunMessage Result { get; set; }

    /// <summary>
    /// Initializes a new instance of the <see cref="RaygunClient" /> class.
    /// </summary>
    /// <param name="apiKey">The API key.</param>
    protected RaygunClient(string apiKey)
    {
      _apiKey = apiKey;      
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="RaygunClient" /> class.
    /// Uses the ApiKey specified in the config file.
    /// </summary>
    protected RaygunClient() : this(RaygunSettings.Settings.ApiKey)
    {
    }

    public void Send(Exception exception)
    {
      if (string.IsNullOrEmpty(_apiKey))
      {
        System.Diagnostics.Trace.WriteLine("ApiKey has not been provided, exception will not be logged");
      }
      else
      {                
        Send(BuildMessage(exception));
      }
    }

    public void Send(RaygunMessage raygunMessage)
    {
      using (var client = new WebClient())
      {
        client.Headers.Add("X-ApiKey", _apiKey);

        try
        {
          client.UploadString(RaygunSettings.Settings.ApiEndpoint, JObject.FromObject(raygunMessage, new JsonSerializer { MissingMemberHandling = MissingMemberHandling.Ignore }).ToString());
        }
        catch (Exception ex)
        {
          System.Diagnostics.Trace.WriteLine(string.Format("Error Logging Exception to Raygun.io {0}", ex.Message));
        }        
      }
      Result = raygunMessage;
    }

    public abstract RaygunMessage BuildMessage(Exception exception);
  }
}
