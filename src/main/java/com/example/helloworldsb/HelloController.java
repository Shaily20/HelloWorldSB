package com.example.helloworldsb;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @GetMapping("/{message}")
    public ResponseEntity<String> home(@PathVariable String message) {
        return ResponseEntity.ok("Hello "+message);
    }

    @GetMapping("/exit")
    public void exitMethod() {
        System.exit(0);
    }
}
