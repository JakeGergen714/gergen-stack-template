package com.gergen.api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.Map;

@SpringBootApplication
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}

@RestController
class RootController {

    @GetMapping("/")
    public Map<String, String> looseSlash() {
        return Map.of("status", "ok", "service", "gergen-stack-api");
    }

    @GetMapping("/api")
    public Map<String, String> root() {
        return Map.of("status", "ok", "service", "gergen-stack-api", "version", "1.0.0");
    }
}
