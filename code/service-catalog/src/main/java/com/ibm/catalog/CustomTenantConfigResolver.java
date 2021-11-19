package com.ibm.catalog;

import javax.enterprise.context.ApplicationScoped;

// Tenant
import io.quarkus.oidc.TenantConfigResolver;
import io.quarkus.oidc.OidcTenantConfig;
import io.vertx.ext.web.RoutingContext;

// ConfigProperties
import org.eclipse.microprofile.config.inject.ConfigProperty;

@ApplicationScoped
public class CustomTenantConfigResolver implements TenantConfigResolver {

    @ConfigProperty(name = "appid.auth-server-url_tenant") 
    private String auth_server_url_tenant;
    @ConfigProperty(name = "appid.client_id_tenant") 
    private String client_id_tenant;
   
    @Override
    public OidcTenantConfig resolve(RoutingContext context) {
        System.out.println("-->log: com.ibm.catalog.CustomTenantResolver.resolve context path: " + context.request().path());

        OidcTenantConfig config = new OidcTenantConfig();

        config.setTenantId("tenant");
        config.setAuthServerUrl(auth_server_url_tenant);
        config.setClientId(client_id_tenant);
        
        System.out.println("-->log: com.ibm.catalog.CustomTenantResolver.resolve issuer: " + config.getToken().getIssuer().toString());
        System.out.println("-->log: com.ibm.catalog.CustomTenantResolver.resolve config: " + config.toString());
            
        return config;

    }
}