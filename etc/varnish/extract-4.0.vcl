vcl 4.0;
import std;

# This is a basic VCL configuration file for varnish.  See the vcl(7)
# man page for details on VCL syntax and semantics.
# 
# Default backend definition.  Set this to point to your content
# server.
# 
#backend default {
#    .host = "127.0.0.1";
#    .port = "8080";
#}

backend localhost {
    .host = "127.0.0.1";
    .port = "8080";
}

backend tile {
    .host = "tile";
    .port = "80";

    .first_byte_timeout = 600s;
    .connect_timeout = 600s;
    .between_bytes_timeout = 600s;
}

backend bbbike {
    .host = "bbbike";
    .port = "80";
    .first_byte_timeout = 300s;
    .connect_timeout = 300s;
    .between_bytes_timeout = 300s;

    .probe = {
        .url = "/test.txt";
        .timeout =  1s;
        .interval = 30s;
        .window = 1;
        .threshold = 1;
    }
}

backend eserte {
    .host = "eserte";
    .port = "80";
    .first_byte_timeout = 300s;
    .connect_timeout = 300s;
    .between_bytes_timeout = 300s;
}

#backend debian9g {
#    .host = "debian9";
#    .port = "3000";
#    .first_byte_timeout = 300s;
#    .connect_timeout = 300s;
#    .between_bytes_timeout = 300s;
#}

backend debian9 {
    .host = "debian9";
    .port = "80";
    .first_byte_timeout = 300s;
    .connect_timeout = 300s;
    .between_bytes_timeout = 300s;
}

backend bbbike_failover {
    .host = "www3.bbbike.org";
    .port = "80";
    .first_byte_timeout = 300s;
    .connect_timeout = 300s;
    .between_bytes_timeout = 300s;

    .probe = {
        .url = "/test.txt";
        .timeout = 5s;
        .interval = 30s;
        .window = 1;
        .threshold = 1;
    }
}


sub vcl_recv {
    # block rough IP addresses
    if (client.ip ~ rough_ip) {
        return (synth(405, "IP address blocked: " + client.ip));
    }

    # allow PURGE from localhost and 192.168.55...
    if (req.method == "PURGE") {
        if (!client.ip ~ purge) {
            return(synth(405, "Not allowed: " + client.ip));
        }
        return (purge);
    }

    # allow only GET, HEAD, and POST requests    
    if (req.method != "GET" &&
        req.method != "HEAD" &&
        req.method != "POST") {
         /* Non-RFC2616 or CONNECT which is weird. */
        return(synth(405, "Unknown request METHOD"));
    }

    # block rogue bots
    if (req.http.user-agent ~ "^(facebookexternalhit|Google Web Preview)") {
        return(synth(405, "rogue bot request"));
    }

    # Redirect to HTTPS, aka "Enforcing SSL behind an SSL termination point"
    if (client.ip != "127.0.0.1" && client.ip != "138.201.59.14" && std.port(server.ip) == 80 && req.http.host ~ "^(munin|dev[1-9]|grafana|extract[1-9]?|extract-pro[1-9]?|eserte|www[1-9]?)\.bbb?ike\.org$") {
        set req.http.x-redir = "https://" + req.http.host + req.url;
        return(synth(850, "Moved permanently"));
    }

    ######################################################################
    # backend config
    #

    # letsencrypt
    if (req.url ~ "^/\.well-known/acme-challenge/") {
        set req.backend_hint = localhost;
        return (pass);
    }

    # other VMs
    else if (req.http.host ~ "^(m\.|api[1-9]?\.|www[1-9]?\.|dev[1-9]?\.|devel[1-9]?\.|)bbbike\.org$") {
        set req.backend_hint = bbbike;

        # failover production @ www1 
        if (req.restarts == 1 || !std.healthy(req.backend_hint)) {
                set req.backend_hint = bbbike_failover;
        }
    } else if (req.http.host ~ "^extract[1-9]?\.bbb?ike\.org$") {
        set req.backend_hint = bbbike;
    } else if (req.http.host ~ "^extract-pro[1-9]?\.bbbike\.org$") {
        set req.backend_hint = bbbike;
    } else if (req.http.host ~ "^download[1-9]?\.bbb?ike\.org$") {
        set req.backend_hint = bbbike;
    } else if (req.http.host ~ "^([a-z]\.)?tile\.bbbike\.org$" || req.http.host ~ "^(mc|maps)\.bbb?ike\.org$") {
        set req.backend_hint = tile;
    } else if (req.http.host ~ "^eserte\.bbbike\.org$" || req.http.host ~ "^.*bbbike\.de$" || req.http.host ~ "^jenkins(-dev)?\.bbbike\.(org|de)$") {
        set req.backend_hint = eserte;
    } else if (req.http.host ~ "^grafana\.bbbike\.org$") {
        set req.backend_hint = debian9;
    } else if (req.http.host ~ "^munin\.bbbike\.org$") {
        set req.backend_hint = debian9;
    } else if (req.http.host ~ "^(www\.|)(cyclerouteplanner\.org|cyclerouteplanner\.com|bbike\.org|cycleroute\.net)$") {
        set req.backend_hint = bbbike;
    } else {
        set req.backend_hint = bbbike;
    }

    # dummy
    if (req.http.host ~ "foobar") {
        set req.backend_hint = bbbike;
    }

    # log real IP address in backend
    if (req.http.x-forwarded-for) {
	set req.http.X-Forwarded-For = req.http.X-Forwarded-For + "," + client.ip;
    } else {
       set req.http.X-Forwarded-For = client.ip;
    }

    ######################################################################
    # backends without caching, pipe/pass

    # don't cache tests
    if (req.url ~ "^/test\.txt$" ) {
       return (pass);
    }

    # do not cache OSM files
    if (req.http.host ~ "^(download[1-9]?)\.bbbike\.org$") {
         return (pipe);
    }

    # development machine of S.R.T
    if (req.http.host ~ "^eserte.*\.bbbike\.org$" || req.http.host ~ "^.*bbbike\.de$") {
	return (pass);
    }

    # jenkins
    if (req.http.host ~ "^jenkins\.bbbike\.(org|de)$") {
	return (pass);
    }

    # no caching
    if (req.http.host ~ "^extract[1-9]?\.bbbike\.org") 		{ return (pass); }
    if (req.http.host ~ "^([a-z]\.)?tile\.bbbike\.org") 	{ return (pass); }
    if (req.http.host ~ "^extract-pro[1-9]?\.bbbike\.org") 	{ return (pass); }
    if (req.http.host ~ "^(dev|devel)[1-9]?\.bbbike\.org$") 	{ return (pass); }
    if (req.http.host ~ "^grafana\.bbbike\.org$") 		{ return (pass); }
    if (req.http.host ~ "^munin\.bbbike\.org$") 		{ return (pass); }
  
    # pipeline post requests trac #4124 
    if (req.method == "POST") {
	return (pass);
    }
        
    # not invented here
    if (req.http.host !~ "\.bbbike\.org$") {
	return (pass);
    }
    
    ######################################################################
    # force caching of images and CSS/JS files
    if (req.url ~ "^/html|^/images|^/feed/|^/osp/|^/cgi/[acdf-z]|.*\.html$|.+/$|^/osm/" || req.http.host ~ "^api[1-9]?.bbbike\.org$" ) {
       unset req.http.cookie;
       unset req.http.User-Agent;
       unset req.http.referer;
       #unset req.http.Accept-Encoding;
    }

    # override page reload requests from impatient users
    if (  req.http.Cache-Control ~ "no-cache" 
       || req.http.Cache-Control ~ "private"
       || req.http.Cache-Control ~ "max-age=0") {

      set req.http.Cache-Control = "max-age=240";
      #unset req.http.Expires;
    }

    if (req.http.host ~ "^(www)[1-9]?\.bbbike\.org$") 	{
       unset req.http.cookie;

       # cache just by major browser type
       call normalize_user_agent;
       set req.http.User-Agent = req.http.X-UA;
    }

    #if (req.http.Authorization || req.http.Cookie) {
    if (req.http.Authorization) {
         /* Not cacheable by default */
        return (pass);
    }

    return (hash);
}

sub vcl_synth {
    if (resp.status == 850) {
        set resp.http.Location = req.http.x-redir;
        set resp.status = 302;
        return (deliver);
    }
}

############################################################
# PURGE config section
#
acl purge {
    "localhost";
    "10.0.0.0"/24;
    "144.76.200.87";
    "88.198.198.75";
    "138.201.59.14";
}

acl rough_ip {
    "85.216.69.114";
}

sub vcl_hit {
    if (req.method == "PURGE") {
        #return(purge);
        #return(synth(200, "Purged vcl_hit."));
    }
}

sub vcl_miss {
    if (req.method == "PURGE") {
        #return(purge);
        #return(synth(200, "Purged vcl_miss." + client.ip));
    }
}



# We're only interested in major categories, not versions, etc...
sub normalize_user_agent {
    if (req.http.user-agent ~ "MSIE 6") {
        set req.http.X-UA = "MSIE 6";
    } else if (req.http.user-agent ~ "MSIE 7") {
        set req.http.X-UA = "MSIE 7";
    } else if (req.http.user-agent ~ "iPhone|Android|iPod|Nokia|Symbian|BlackBerry|SonyEricsson") {
        set req.http.X-UA = "Mobile";
    } else {
        set req.http.X-UA = "none";
    }
}

# 
# Below is a commented-out copy of the default VCL logic.  If you
# redefine any of these subroutines, the built-in logic will be
# appended to your code.
# sub vcl_recv {
#     if (req.restarts == 0) {
# 	if (req.http.x-forwarded-for) {
# 	    set req.http.X-Forwarded-For =
# 		req.http.X-Forwarded-For + ", " + client.ip;
# 	} else {
# 	    set req.http.X-Forwarded-For = client.ip;
# 	}
#     }
#     if (req.request != "GET" &&
#       req.request != "HEAD" &&
#       req.request != "PUT" &&
#       req.request != "POST" &&
#       req.request != "TRACE" &&
#       req.request != "OPTIONS" &&
#       req.request != "DELETE") {
#         /* Non-RFC2616 or CONNECT which is weird. */
#         return (pipe);
#     }
#     if (req.request != "GET" && req.request != "HEAD") {
#         /* We only deal with GET and HEAD by default */
#         return (pass);
#     }
#     if (req.http.Authorization || req.http.Cookie) {
#         /* Not cacheable by default */
#         return (pass);
#     }
#     return (lookup);
# }
# 
# sub vcl_pipe {
#     # Note that only the first request to the backend will have
#     # X-Forwarded-For set.  If you use X-Forwarded-For and want to
#     # have it set for all requests, make sure to have:
#     # set bereq.http.connection = "close";
#     # here.  It is not set by default as it might break some broken web
#     # applications, like IIS with NTLM authentication.
#     return (pipe);
# }
# 
# sub vcl_pass {
#     return (pass);
# }
# 
# sub vcl_hash {
#     hash_data(req.url);
#     if (req.http.host) {
#         hash_data(req.http.host);
#     } else {
#         hash_data(server.ip);
#     }
#     return (hash);
# }
# 
# sub vcl_hit {
#     return (deliver);
# }
# 
# sub vcl_miss {
#     return (fetch);
# }
# 

sub vcl_backend_response {
    # ???
    #if (req.http.host ~ "^(www)[1-9]?\.bbbike\.org$") 	{
    #    unset beresp.http.set-cookie;
    #}

#     if (beresp.ttl <= 0s ||
#         beresp.http.Set-Cookie ||
#         beresp.http.Vary == "*") {
# 		/*
# 		 * Mark as "Hit-For-Pass" for the next 2 minutes
# 		 */
# 		set beresp.ttl = 120 s;
# 		return (hit_for_pass);
#     }
     return (deliver);
}

# 
# sub vcl_deliver {
#     return (deliver);
# }
# 
# sub vcl_error {
#     set obj.http.Content-Type = "text/html; charset=utf-8";
#     set obj.http.Retry-After = "5";
#     synthetic {"
# <?xml version="1.0" encoding="utf-8"?>
# <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
#  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
# <html>
#   <head>
#     <title>"} + obj.status + " " + obj.response + {"</title>
#   </head>
#   <body>
#     <h1>Error "} + obj.status + " " + obj.response + {"</h1>
#     <p>"} + obj.response + {"</p>
#     <h3>Guru Meditation:</h3>
#     <p>XID: "} + req.xid + {"</p>
#     <hr>
#     <p>Varnish cache server</p>
#   </body>
# </html>
# "};
#     return (deliver);
# }
# 
# sub vcl_init {
# 	return (ok);
# }
# 
# sub vcl_fini {
# 	return (ok);
# }
