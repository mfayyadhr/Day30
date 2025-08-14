package com.example.java_openshift.controllers;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class MyController {

    @GetMapping("/")
    public String home() {
        return "index"; // Mengembalikan nama file HTML tanpa ekstensi
    }
}