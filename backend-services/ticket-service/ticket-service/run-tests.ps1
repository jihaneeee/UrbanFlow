# ============================================
# URBANFLOW TICKET SERVICE - TEST SUITE
# ============================================

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "   URBANFLOW TICKET SERVICE - COMPREHENSIVE TESTS" -ForegroundColor Cyan
Write-Host "========================================================`n" -ForegroundColor Cyan

$baseUrl = "http://localhost:8082"
$testResults = @()

# TEST 1: Health Check
Write-Host "`n[TEST 1] Health Check" -ForegroundColor Yellow
Write-Host "-------------------------------------------------------" -ForegroundColor Gray

try {
    $health = Invoke-RestMethod -Uri "$baseUrl/actuator/health" -Method GET
    
    Write-Host "[OK] Service Status: $($health.status)" -ForegroundColor Green
    Write-Host "[OK] Database: $($health.components.db.status)" -ForegroundColor Green
    Write-Host "[OK] RabbitMQ: $($health.components.rabbit.status)" -ForegroundColor Green
    
    $testResults += @{Test="Health Check"; Status="PASSED"}
} catch {
    Write-Host "[FAIL] Health Check Failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test="Health Check"; Status="FAILED"}
}

Start-Sleep -Seconds 2

# TEST 2: Create Ticket
Write-Host "`n[TEST 2] Create Ticket - Valid Request" -ForegroundColor Yellow
Write-Host "-------------------------------------------------------" -ForegroundColor Gray

$ticketRequest = @{
    userId = "user123"
    routeId = 5
    origin = "Downtown Station"
    destination = "Airport Terminal"
    departureTime = "2025-11-16T14:30:00"
    arrivalTime = "2025-11-16T15:15:00"
    price = 12.50
    seatNumber = "A12"
} | ConvertTo-Json

try {
    $ticket1 = Invoke-RestMethod -Uri "$baseUrl/api/tickets" -Method POST -ContentType "application/json" -Body $ticketRequest
    
    Write-Host "[OK] Ticket Created Successfully" -ForegroundColor Green
    Write-Host "  Ticket ID: $($ticket1.id)" -ForegroundColor White
    Write-Host "  Status: $($ticket1.status)" -ForegroundColor White
    Write-Host "  Seat: $($ticket1.seatNumber)" -ForegroundColor White
    
    $global:ticketId1 = $ticket1.id
    $testResults += @{Test="Create Ticket"; Status="PASSED"}
} catch {
    Write-Host "[FAIL] Failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test="Create Ticket"; Status="FAILED"}
}

Start-Sleep -Seconds 2

# TEST 3: Duplicate Seat
Write-Host "`n[TEST 3] Duplicate Seat Prevention" -ForegroundColor Yellow
Write-Host "-------------------------------------------------------" -ForegroundColor Gray

try {
    $duplicateTicket = Invoke-RestMethod -Uri "$baseUrl/api/tickets" -Method POST -ContentType "application/json" -Body $ticketRequest -ErrorAction Stop
    
    Write-Host "[FAIL] Duplicate seat was allowed" -ForegroundColor Red
    $testResults += @{Test="Duplicate Prevention"; Status="FAILED"}
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "[OK] Correctly rejected duplicate seat" -ForegroundColor Green
        $testResults += @{Test="Duplicate Prevention"; Status="PASSED"}
    } else {
        Write-Host "[FAIL] Unexpected error" -ForegroundColor Red
        $testResults += @{Test="Duplicate Prevention"; Status="FAILED"}
    }
}

Start-Sleep -Seconds 2

# TEST 4: Invalid Data
Write-Host "`n[TEST 4] Validation - Invalid Data" -ForegroundColor Yellow
Write-Host "-------------------------------------------------------" -ForegroundColor Gray

$invalidRequest = @{
    userId = ""
    routeId = 5
    price = -10
} | ConvertTo-Json

try {
    $invalidTicket = Invoke-RestMethod -Uri "$baseUrl/api/tickets" -Method POST -ContentType "application/json" -Body $invalidRequest -ErrorAction Stop
    
    Write-Host "[FAIL] Invalid data was accepted" -ForegroundColor Red
    $testResults += @{Test="Validation"; Status="FAILED"}
} catch {
    if ($_.Exception.Response.StatusCode -eq 400) {
        Write-Host "[OK] Correctly rejected invalid data" -ForegroundColor Green
        $testResults += @{Test="Validation"; Status="PASSED"}
    } else {
        Write-Host "[FAIL] Unexpected error" -ForegroundColor Red
        $testResults += @{Test="Validation"; Status="FAILED"}
    }
}

Start-Sleep -Seconds 2

# TEST 5: Get Ticket by ID
Write-Host "`n[TEST 5] Get Ticket by ID" -ForegroundColor Yellow
Write-Host "-------------------------------------------------------" -ForegroundColor Gray

try {
    $retrievedTicket = Invoke-RestMethod -Uri "$baseUrl/api/tickets/$global:ticketId1" -Method GET
    
    Write-Host "[OK] Ticket Retrieved: ID $($retrievedTicket.id)" -ForegroundColor Green
    $testResults += @{Test="Get Ticket"; Status="PASSED"}
} catch {
    Write-Host "[FAIL] Failed to retrieve ticket" -ForegroundColor Red
    $testResults += @{Test="Get Ticket"; Status="FAILED"}
}

Start-Sleep -Seconds 2

# TEST 6: Get Non-Existent Ticket
Write-Host "`n[TEST 6] Get Non-Existent Ticket (404)" -ForegroundColor Yellow
Write-Host "-------------------------------------------------------" -ForegroundColor Gray

try {
    $nonExistent = Invoke-RestMethod -Uri "$baseUrl/api/tickets/99999" -Method GET -ErrorAction Stop
    
    Write-Host "[FAIL] Non-existent ticket returned data" -ForegroundColor Red
    $testResults += @{Test="404 Handling"; Status="FAILED"}
} catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host "[OK] Correctly returned 404" -ForegroundColor Green
        $testResults += @{Test="404 Handling"; Status="PASSED"}
    } else {
        Write-Host "[FAIL] Unexpected error" -ForegroundColor Red
        $testResults += @{Test="404 Handling"; Status="FAILED"}
    }
}

Start-Sleep -Seconds 2

# TEST 7: Get User Tickets
Write-Host "`n[TEST 7] Get All User Tickets" -ForegroundColor Yellow
Write-Host "-------------------------------------------------------" -ForegroundColor Gray

try {
    $userTickets = Invoke-RestMethod -Uri "$baseUrl/api/tickets/user/user123" -Method GET
    
    Write-Host "[OK] Retrieved $($userTickets.Count) ticket(s)" -ForegroundColor Green
    $testResults += @{Test="Get User Tickets"; Status="PASSED"}
} catch {
    Write-Host "[FAIL] Failed to retrieve user tickets" -ForegroundColor Red
    $testResults += @{Test="Get User Tickets"; Status="FAILED"}
}

Start-Sleep -Seconds 2

# TEST 8: Create Second Ticket
Write-Host "`n[TEST 8] Create Second Ticket (Different Seat)" -ForegroundColor Yellow
Write-Host "-------------------------------------------------------" -ForegroundColor Gray

$ticket2Request = @{
    userId = "user123"
    routeId = 5
    origin = "Downtown Station"
    destination = "Airport Terminal"
    departureTime = "2025-11-16T14:30:00"
    arrivalTime = "2025-11-16T15:15:00"
    price = 12.50
    seatNumber = "B05"
} | ConvertTo-Json

try {
    $ticket2 = Invoke-RestMethod -Uri "$baseUrl/api/tickets" -Method POST -ContentType "application/json" -Body $ticket2Request
    
    Write-Host "[OK] Second ticket created: Seat $($ticket2.seatNumber)" -ForegroundColor Green
    $global:ticketId2 = $ticket2.id
    $testResults += @{Test="Create Second Ticket"; Status="PASSED"}
} catch {
    Write-Host "[FAIL] Failed to create second ticket" -ForegroundColor Red
    $testResults += @{Test="Create Second Ticket"; Status="FAILED"}
}

Start-Sleep -Seconds 2

# TEST 9: Use Ticket
Write-Host "`n[TEST 9] Use Ticket (Scan at Gate)" -ForegroundColor Yellow
Write-Host "-------------------------------------------------------" -ForegroundColor Gray

try {
    $usedTicket = Invoke-RestMethod -Uri "$baseUrl/api/tickets/$global:ticketId2/use?userId=user123" -Method PUT
    
    Write-Host "[OK] Ticket used successfully - Status: $($usedTicket.status)" -ForegroundColor Green
    $testResults += @{Test="Use Ticket"; Status="PASSED"}
} catch {
    Write-Host "[FAIL] Failed to use ticket" -ForegroundColor Red
    $testResults += @{Test="Use Ticket"; Status="FAILED"}
}

Start-Sleep -Seconds 2

# TEST 10: Reuse Ticket
Write-Host "`n[TEST 10] Try to Reuse Ticket (Should Fail)" -ForegroundColor Yellow
Write-Host "-------------------------------------------------------" -ForegroundColor Gray

try {
    $reusedTicket = Invoke-RestMethod -Uri "$baseUrl/api/tickets/$global:ticketId2/use?userId=user123" -Method PUT -ErrorAction Stop
    
    Write-Host "[FAIL] Used ticket was accepted again" -ForegroundColor Red
    $testResults += @{Test="Prevent Reuse"; Status="FAILED"}
} catch {
    if ($_.Exception.Response.StatusCode -eq 400) {
        Write-Host "[OK] Correctly rejected used ticket" -ForegroundColor Green
        $testResults += @{Test="Prevent Reuse"; Status="PASSED"}
    } else {
        Write-Host "[FAIL] Unexpected error" -ForegroundColor Red
        $testResults += @{Test="Prevent Reuse"; Status="FAILED"}
    }
}

Start-Sleep -Seconds 2

# TEST 11: Cancel Ticket
Write-Host "`n[TEST 11] Cancel Ticket" -ForegroundColor Yellow
Write-Host "-------------------------------------------------------" -ForegroundColor Gray

try {
    $cancelledTicket = Invoke-RestMethod -Uri "$baseUrl/api/tickets/$global:ticketId1/cancel?userId=user123" -Method PUT
    
    Write-Host "[OK] Ticket cancelled - Status: $($cancelledTicket.status)" -ForegroundColor Green
    $testResults += @{Test="Cancel Ticket"; Status="PASSED"}
} catch {
    Write-Host "[FAIL] Failed to cancel ticket" -ForegroundColor Red
    $testResults += @{Test="Cancel Ticket"; Status="FAILED"}
}

Start-Sleep -Seconds 2

# TEST 12: Re-cancel Ticket
Write-Host "`n[TEST 12] Try to Re-cancel Ticket (Should Fail)" -ForegroundColor Yellow
Write-Host "-------------------------------------------------------" -ForegroundColor Gray

try {
    $recancelledTicket = Invoke-RestMethod -Uri "$baseUrl/api/tickets/$global:ticketId1/cancel?userId=user123" -Method PUT -ErrorAction Stop
    
    Write-Host "[FAIL] Cancelled ticket was accepted again" -ForegroundColor Red
    $testResults += @{Test="Prevent Re-cancellation"; Status="FAILED"}
} catch {
    if ($_.Exception.Response.StatusCode -eq 400) {
        Write-Host "[OK] Correctly rejected cancelled ticket" -ForegroundColor Green
        $testResults += @{Test="Prevent Re-cancellation"; Status="PASSED"}
    } else {
        Write-Host "[FAIL] Unexpected error" -ForegroundColor Red
        $testResults += @{Test="Prevent Re-cancellation"; Status="FAILED"}
    }
}

Start-Sleep -Seconds 2

# TEST SUMMARY
Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "                   TEST SUMMARY" -ForegroundColor Cyan
Write-Host "========================================================`n" -ForegroundColor Cyan

$passed = ($testResults | Where-Object { $_.Status -eq "PASSED" }).Count
$failed = ($testResults | Where-Object { $_.Status -eq "FAILED" }).Count

Write-Host "Total Tests: $($testResults.Count)" -ForegroundColor White
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red

Write-Host "`nDetailed Results:" -ForegroundColor White
Write-Host "-------------------------------------------------------" -ForegroundColor Gray

foreach ($result in $testResults) {
    if ($result.Status -eq "PASSED") {
        Write-Host "[OK] $($result.Test)" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] $($result.Test)" -ForegroundColor Red
    }
}

Write-Host "`n========================================================" -ForegroundColor Cyan

if ($failed -eq 0) {
    Write-Host "SUCCESS: ALL TESTS PASSED!" -ForegroundColor Green
} else {
    Write-Host "WARNING: Some tests failed" -ForegroundColor Red
}

Write-Host "`nRabbitMQ Management: http://localhost:15672 (guest/guest)" -ForegroundColor Yellow
Write-Host "PostgreSQL: localhost:5433 (postgres/postgres123)" -ForegroundColor Yellow
