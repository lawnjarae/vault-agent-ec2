package com.hashicorp.cdl.moderizing_brownfield_apps;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.context.config.annotation.RefreshScope;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
@RefreshScope
public class WebController {

    @Autowired
    private ConfigProperties configProperties;

    @Value("${spring.datasource.username:defaultUsername}")
    private String postgresUsername;

    @Value("${spring.datasource.password:defaultPassword}")
    private String postgresPassword;

    @GetMapping("/")
    public String getConfig(Model model) {
        model.addAttribute("apiKey", configProperties.getApiKey());
        model.addAttribute("secretData", configProperties.getSecretData());
        model.addAttribute("postgresUsername", postgresUsername);
        model.addAttribute("postgresPassword", postgresPassword);
        model.addAttribute("counter", configProperties.getCounter());
        return "config";
    }
}
