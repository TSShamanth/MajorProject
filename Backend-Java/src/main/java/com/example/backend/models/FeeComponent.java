package com.example.backend.models;

public class FeeComponent {
    private String name;
    private double amount;

    public FeeComponent() {
    }

    public FeeComponent(String name, double amount) {
        this.name = name;
        this.amount = amount;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public double getAmount() {
        return amount;
    }

    public void setAmount(double amount) {
        this.amount = amount;
    }
}
