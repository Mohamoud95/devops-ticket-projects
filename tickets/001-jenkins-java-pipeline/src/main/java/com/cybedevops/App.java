package com.cybedevops;

public final class App {
    private App() {
    }

    public static String greeting(String name) {
        if (name == null || name.isBlank()) {
            return "Hello, DevOps!";
        }
        return "Hello, " + name.trim() + "!";
    }

    public static void main(String[] args) {
        String name = args.length == 0 ? "DevOps" : args[0];
        System.out.println(greeting(name));
    }
}
