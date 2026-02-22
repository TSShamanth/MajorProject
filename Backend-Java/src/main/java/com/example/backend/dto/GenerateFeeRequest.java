package com.example.backend.dto;

import java.util.Date;

public class GenerateFeeRequest {
    private String feeStructureId;
    private Date dueDate;

    public GenerateFeeRequest() {
    }

    public String getFeeStructureId() {
        return feeStructureId;
    }

    public void setFeeStructureId(String feeStructureId) {
        this.feeStructureId = feeStructureId;
    }

    public Date getDueDate() {
        return dueDate;
    }

    public void setDueDate(Date dueDate) {
        this.dueDate = dueDate;
    }
}
