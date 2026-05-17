package com.example.backend.service;

public class ChatContextHolder {
    private static final InheritableThreadLocal<ChatContext> contextHolder = new InheritableThreadLocal<>();

    public static void setContext(ChatContext context) {
        contextHolder.set(context);
    }

    public static ChatContext getContext() {
        return contextHolder.get();
    }

    public static void clearContext() {
        contextHolder.remove();
    }
}
