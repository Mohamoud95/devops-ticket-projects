package com.cybedevops;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class AppTest {
    @Test
    void greetsAProvidedName() {
        assertEquals("Hello, Jenkins!", App.greeting("Jenkins"));
    }

    @Test
    void usesDefaultWhenNameIsBlank() {
        assertEquals("Hello, DevOps!", App.greeting("  "));
    }     
    
    @Test
    void usesDefaultWhenNameIsNull() {
        assertEquals("Hello, DevOps!", App.greeting(null));
    }
}
