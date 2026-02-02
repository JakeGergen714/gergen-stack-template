package com.gergen.api;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.Map;

@RestController
public class RootController {

    @GetMapping("/")
    public Map<String, String> looseSlash() {
        return Map.of("status", "ok", "service", "gergen-stack-api");
    }

    @GetMapping("/api")
    public Map<String, String> root() {
        return Map.of("status", "ok", "service", "gergen-stack-api", "version", "1.0.0");
    }
}
