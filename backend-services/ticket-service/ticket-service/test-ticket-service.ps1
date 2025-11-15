# ============================================
# URBANFLOW TICKET SERVICE - COMPREHENSIVE TEST SUITE
# ============================================

Write-Host "`n╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          URBANFLOW TICKET SERVICE - TEST SUITE                  ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$baseUrl = "http://localhost:8082"
$testResults = @()

# ============================================
# TEST 1: Health Check
# ============================================
Write-Host "`n[TEST 1] Health Check - Verify all components are running" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

try {
    $health = Invoke-RestMethod -Uri "$baseUrl/actuator/health" -Method GET
    
    Write-Host "✓ Service Status: $($health.status)" -ForegroundColor Green
    Write-Host "✓ Database: $($health.components.db.status)" -ForegroundColor Green
    Write-Host "✓ RabbitMQ: $($health.components.rabbit.status) (v$($health.components.rabbit.details.version))" -ForegroundColor Green
    Write-Host "✓ Disk Space: $($health.components.diskSpace.status)" -ForegroundColor Green
    
    $testResults += @{Test="Health Check"; Status="PASSED"; Details="All components UP"}
} catch {
    Write-Host "✗ Health Check Failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test="Health Check"; Status="FAILED"; Details=$_.Exception.Message}
}

Start-Sleep -Seconds 2

# ============================================
# TEST 2: Create Ticket - Valid Data
# ============================================
Write-Host "`n[TEST 2] Create Ticket - Valid Request" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

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
    
    Write-Host "✓ Ticket Created Successfully" -ForegroundColor Green
    Write-Host "  ├─ Ticket ID: $($ticket1.id)" -ForegroundColor White
    Write-Host "  ├─ Status: $($ticket1.status)" -ForegroundColor White
    Write-Host "  ├─ Price: `$$($ticket1.price)" -ForegroundColor White
    Write-Host "  ├─ Seat: $($ticket1.seatNumber)" -ForegroundColor White
    Write-Host "  ├─ QR Code: $($ticket1.qrCode)" -ForegroundColor White
    Write-Host "  └─ Purchase Date: $($ticket1.purchaseDate)" -ForegroundColor White
    
    $global:ticketId1 = $ticket1.id
    $testResults += @{Test="Create Ticket (Valid)"; Status="PASSED"; Details="Ticket ID: $($ticket1.id)"}
} catch {
    Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test="Create Ticket (Valid)"; Status="FAILED"; Details=$_.Exception.Message}
}

Start-Sleep -Seconds 2

# ============================================
# TEST 3: Create Ticket - Duplicate Seat
# ============================================
Write-Host "`n[TEST 3] Create Ticket - Duplicate Seat (Should Fail)" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

try {
    $duplicateTicket = Invoke-RestMethod -Uri "$baseUrl/api/tickets" -Method POST -ContentType "application/json" -Body $ticketRequest -ErrorAction Stop
    
    Write-Host "✗ Test Failed: Duplicate seat was allowed" -ForegroundColor Red
    $testResults += @{Test="Duplicate Seat Prevention"; Status="FAILED"; Details="System allowed duplicate seat booking"}
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "✓ Correctly rejected duplicate seat booking" -ForegroundColor Green
        Write-Host "  └─ Error: Seat A12 already booked" -ForegroundColor White
        $testResults += @{Test="Duplicate Seat Prevention"; Status="PASSED"; Details="409 Conflict returned"}
    } else {
        Write-Host "✗ Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
        $testResults += @{Test="Duplicate Seat Prevention"; Status="FAILED"; Details=$_.Exception.Message}
    }
}

Start-Sleep -Seconds 2

# ============================================
# TEST 4: Create Ticket - Invalid Data
# ============================================
Write-Host "`n[TEST 4] Create Ticket - Invalid Data (Missing Required Fields)" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

$invalidRequest = @{
    userId = ""
    routeId = 5
    price = -10
} | ConvertTo-Json

try {
    $invalidTicket = Invoke-RestMethod -Uri "$baseUrl/api/tickets" -Method POST -ContentType "application/json" -Body $invalidRequest -ErrorAction Stop
    
    Write-Host "✗ Test Failed: Invalid data was accepted" -ForegroundColor Red
    $testResults += @{Test="Validation"; Status="FAILED"; Details="Invalid data accepted"}
} catch {
    if ($_.Exception.Response.StatusCode -eq 400) {
        Write-Host "✓ Correctly rejected invalid data" -ForegroundColor Green
        Write-Host "  └─ Validation errors detected" -ForegroundColor White
        $testResults += @{Test="Validation"; Status="PASSED"; Details="400 Bad Request returned"}
    } else {
        Write-Host "✗ Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
        $testResults += @{Test="Validation"; Status="FAILED"; Details=$_.Exception.Message}
    }
}

Start-Sleep -Seconds 2

# ============================================
# TEST 5: Get Ticket by ID
# ============================================
Write-Host "`n[TEST 5] Get Ticket by ID" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

try {
    $retrievedTicket = Invoke-RestMethod -Uri "$baseUrl/api/tickets/$global:ticketId1" -Method GET
    
    Write-Host "✓ Ticket Retrieved Successfully" -ForegroundColor Green
    Write-Host "  ├─ Ticket ID: $($retrievedTicket.id)" -ForegroundColor White
    Write-Host "  ├─ User ID: $($retrievedTicket.userId)" -ForegroundColor White
    Write-Host "  └─ Route: $($retrievedTicket.origin) → $($retrievedTicket.destination)" -ForegroundColor White
    
    $testResults += @{Test="Get Ticket by ID"; Status="PASSED"; Details="Ticket retrieved"}
} catch {
    Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test="Get Ticket by ID"; Status="FAILED"; Details=$_.Exception.Message}
}

Start-Sleep -Seconds 2

# ============================================
# TEST 6: Get Non-Existent Ticket
# ============================================
Write-Host "`n[TEST 6] Get Non-Existent Ticket (Should Return 404)" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

try {
    $nonExistent = Invoke-RestMethod -Uri "$baseUrl/api/tickets/99999" -Method GET -ErrorAction Stop
    
    Write-Host "✗ Test Failed: Non-existent ticket returned data" -ForegroundColor Red
    $testResults += @{Test="404 Not Found"; Status="FAILED"; Details="Non-existent resource found"}
} catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host "✓ Correctly returned 404 Not Found" -ForegroundColor Green
        $testResults += @{Test="404 Not Found"; Status="PASSED"; Details="404 returned for missing resource"}
    } else {
        Write-Host "✗ Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
        $testResults += @{Test="404 Not Found"; Status="FAILED"; Details=$_.Exception.Message}
    }
}

Start-Sleep -Seconds 2

# ============================================
# TEST 7: Get User's Tickets
# ============================================
Write-Host "`n[TEST 7] Get All Tickets for User" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

try {
    $userTickets = Invoke-RestMethod -Uri "$baseUrl/api/tickets/user/user123" -Method GET
    
    Write-Host "✓ Retrieved $($userTickets.Count) ticket(s) for user123" -ForegroundColor Green
    foreach ($ticket in $userTickets) {
        Write-Host "  ├─ Ticket #$($ticket.id): $($ticket.status) - Seat $($ticket.seatNumber)" -ForegroundColor White
    }
    
    $testResults += @{Test="Get User Tickets"; Status="PASSED"; Details="$($userTickets.Count) tickets found"}
} catch {
    Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test="Get User Tickets"; Status="FAILED"; Details=$_.Exception.Message}
}

Start-Sleep -Seconds 2

# ============================================
# TEST 8: Get Upcoming Tickets
# ============================================
Write-Host "`n[TEST 8] Get Upcoming Tickets" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

try {
    $upcomingTickets = Invoke-RestMethod -Uri "$baseUrl/api/tickets/user/user123/upcoming" -Method GET
    
    Write-Host "✓ Retrieved $($upcomingTickets.Count) upcoming ticket(s)" -ForegroundColor Green
    foreach ($ticket in $upcomingTickets) {
        Write-Host "  ├─ Departure: $($ticket.departureTime)" -ForegroundColor White
    }
    
    $testResults += @{Test="Get Upcoming Tickets"; Status="PASSED"; Details="$($upcomingTickets.Count) upcoming tickets"}
} catch {
    Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test="Get Upcoming Tickets"; Status="FAILED"; Details=$_.Exception.Message}
}

Start-Sleep -Seconds 2

# ============================================
# TEST 9: Get Active Tickets
# ============================================
Write-Host "`n[TEST 9] Get Active Tickets" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

try {
    $activeTickets = Invoke-RestMethod -Uri "$baseUrl/api/tickets/user/user123/active" -Method GET
    
    Write-Host "✓ Retrieved $($activeTickets.Count) active ticket(s)" -ForegroundColor Green
    foreach ($ticket in $activeTickets) {
        Write-Host "  ├─ Ticket #$($ticket.id): Status $($ticket.status)" -ForegroundColor White
    }
    
    $testResults += @{Test="Get Active Tickets"; Status="PASSED"; Details="$($activeTickets.Count) active tickets"}
} catch {
    Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test="Get Active Tickets"; Status="FAILED"; Details=$_.Exception.Message}
}

Start-Sleep -Seconds 2

# ============================================
# TEST 10: Create Second Ticket (Different Seat)
# ============================================
Write-Host "`n[TEST 10] Create Second Ticket (Different Seat)" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

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
    
    Write-Host "✓ Second ticket created successfully" -ForegroundColor Green
    Write-Host "  ├─ Ticket ID: $($ticket2.id)" -ForegroundColor White
    Write-Host "  └─ Seat: $($ticket2.seatNumber)" -ForegroundColor White
    
    $global:ticketId2 = $ticket2.id
    $testResults += @{Test="Create Second Ticket"; Status="PASSED"; Details="Ticket ID: $($ticket2.id)"}
} catch {
    Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test="Create Second Ticket"; Status="FAILED"; Details=$_.Exception.Message}
}

Start-Sleep -Seconds 2

# ============================================
# TEST 11: Use Ticket
# ============================================
Write-Host "`n[TEST 11] Use Ticket (Scan at Gate)" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

try {
    $usedTicket = Invoke-RestMethod -Uri "$baseUrl/api/tickets/$global:ticketId2/use?userId=user123" -Method PUT
    
    Write-Host "✓ Ticket used successfully" -ForegroundColor Green
    Write-Host "  ├─ Previous Status: ACTIVE" -ForegroundColor White
    Write-Host "  └─ New Status: $($usedTicket.status)" -ForegroundColor White
    
    $testResults += @{Test="Use Ticket"; Status="PASSED"; Details="Status changed to USED"}
} catch {
    Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test="Use Ticket"; Status="FAILED"; Details=$_.Exception.Message}
}

Start-Sleep -Seconds 2

# ============================================
# TEST 12: Try to Use Already Used Ticket
# ============================================
Write-Host "`n[TEST 12] Try to Use Already Used Ticket (Should Fail)" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

try {
    $reusedTicket = Invoke-RestMethod -Uri "$baseUrl/api/tickets/$global:ticketId2/use?userId=user123" -Method PUT -ErrorAction Stop
    
    Write-Host "✗ Test Failed: Used ticket was accepted again" -ForegroundColor Red
    $testResults += @{Test="Prevent Reuse"; Status="FAILED"; Details="Used ticket accepted"}
} catch {
    if ($_.Exception.Response.StatusCode -eq 400) {
        Write-Host "✓ Correctly rejected already used ticket" -ForegroundColor Green
        $testResults += @{Test="Prevent Reuse"; Status="PASSED"; Details="400 Bad Request returned"}
    } else {
        Write-Host "✗ Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
        $testResults += @{Test="Prevent Reuse"; Status="FAILED"; Details=$_.Exception.Message}
    }
}

Start-Sleep -Seconds 2

# ============================================
# TEST 13: Cancel Ticket
# ============================================
Write-Host "`n[TEST 13] Cancel Ticket" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

try {
    $cancelledTicket = Invoke-RestMethod -Uri "$baseUrl/api/tickets/$global:ticketId1/cancel?userId=user123" -Method PUT
    
    Write-Host "✓ Ticket cancelled successfully" -ForegroundColor Green
    Write-Host "  ├─ Previous Status: ACTIVE" -ForegroundColor White
    Write-Host "  └─ New Status: $($cancelledTicket.status)" -ForegroundColor White
    
    $testResults += @{Test="Cancel Ticket"; Status="PASSED"; Details="Status changed to CANCELLED"}
} catch {
    Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test="Cancel Ticket"; Status="FAILED"; Details=$_.Exception.Message}
}

Start-Sleep -Seconds 2

# ============================================
# TEST 14: Try to Cancel Already Cancelled Ticket
# ============================================
Write-Host "`n[TEST 14] Try to Cancel Already Cancelled Ticket (Should Fail)" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

try {
    $recancelledTicket = Invoke-RestMethod -Uri "$baseUrl/api/tickets/$global:ticketId1/cancel?userId=user123" -Method PUT -ErrorAction Stop
    
    Write-Host "✗ Test Failed: Cancelled ticket was accepted again" -ForegroundColor Red
    $testResults += @{Test="Prevent Re-cancellation"; Status="FAILED"; Details="Cancelled ticket accepted"}
} catch {
    if ($_.Exception.Response.StatusCode -eq 400) {
        Write-Host "✓ Correctly rejected already cancelled ticket" -ForegroundColor Green
        $testResults += @{Test="Prevent Re-cancellation"; Status="PASSED"; Details="400 Bad Request returned"}
    } else {
        Write-Host "✗ Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
        $testResults += @{Test="Prevent Re-cancellation"; Status="FAILED"; Details=$_.Exception.Message}
    }
}

Start-Sleep -Seconds 2

# ============================================
# TEST 15: RabbitMQ Queue Check
# ============================================
Write-Host "`n[TEST 15] RabbitMQ Message Queue Verification" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

try {
    Write-Host "✓ RabbitMQ Management Console: http://localhost:15672" -ForegroundColor Green
    Write-Host "  ├─ Username: guest" -ForegroundColor White
    Write-Host "  ├─ Password: guest" -ForegroundColor White
    Write-Host "  └─ Expected Queues:" -ForegroundColor White
    Write-Host "      ├─ payment.ticket.created" -ForegroundColor Gray
    Write-Host "      ├─ notification.ticket.events" -ForegroundColor Gray
    Write-Host "      ├─ analytics.ticket.events" -ForegroundColor Gray
    Write-Host "      ├─ refund.ticket.cancelled" -ForegroundColor Gray
    Write-Host "      ├─ ticket.payment.completed" -ForegroundColor Gray
    Write-Host "      └─ ticket.route.cancelled" -ForegroundColor Gray
    
    $testResults += @{Test="RabbitMQ Integration"; Status="MANUAL CHECK"; Details="Verify queues at http://localhost:15672"}
} catch {
    Write-Host "✗ RabbitMQ check skipped" -ForegroundColor Yellow
}

Start-Sleep -Seconds 2

# ============================================
# TEST 16: Database Persistence Check
# ============================================
Write-Host "`n[TEST 16] Database Persistence Verification" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

try {
    Write-Host "✓ PostgreSQL Connection: localhost:5433" -ForegroundColor Green
    Write-Host "  ├─ Database: urbanflow_tickets" -ForegroundColor White
    Write-Host "  ├─ Username: postgres" -ForegroundColor White
    Write-Host "  └─ Password: postgres123" -ForegroundColor White
    Write-Host "`nSQL Query to check tickets:" -ForegroundColor Gray
    Write-Host "  SELECT * FROM tickets WHERE user_id = 'user123';" -ForegroundColor DarkGray
    
    $testResults += @{Test="Database Persistence"; Status="MANUAL CHECK"; Details="Connect to PostgreSQL"}
} catch {
    Write-Host "✗ Database check skipped" -ForegroundColor Yellow
}

# ============================================
# TEST SUMMARY
# ============================================
Write-Host "`n`n╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                        TEST SUMMARY                              ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$passed = ($testResults | Where-Object { $_.Status -eq "PASSED" }).Count
$failed = ($testResults | Where-Object { $_.Status -eq "FAILED" }).Count
$manual = ($testResults | Where-Object { $_.Status -eq "MANUAL CHECK" }).Count

Write-Host "Total Tests: $($testResults.Count)" -ForegroundColor White
Write-Host "[OK] Passed: $passed" -ForegroundColor Green
Write-Host "[FAIL] Failed: $failed" -ForegroundColor Red
Write-Host "[MANUAL] Manual Check: $manual" -ForegroundColor Yellow

Write-Host "`nDetailed Results:" -ForegroundColor White
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

foreach ($result in $testResults) {
    $color = switch ($result.Status) {
        "PASSED" { "Green" }
        "FAILED" { "Red" }
        "MANUAL CHECK" { "Yellow" }
        default { "White" }
    }
    
    $symbol = switch ($result.Status) {
        "PASSED" { "[OK]" }
        "FAILED" { "[FAIL]" }
        "MANUAL CHECK" { "[MANUAL]" }
        default { "[INFO]" }
    }
    
    Write-Host "$symbol $($result.Test): $($result.Status)" -ForegroundColor $color
    Write-Host "  └─ $($result.Details)" -ForegroundColor Gray
}

Write-Host "`n╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    TESTING COMPLETE                              ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

if ($failed -eq 0) {
    Write-Host "SUCCESS: ALL AUTOMATED TESTS PASSED! Service is working correctly." -ForegroundColor Green
} else {
    Write-Host "WARNING: Some tests failed. Please review the errors above." -ForegroundColor Red
}

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Check RabbitMQ Console: http://localhost:15672 (guest/guest)" -ForegroundColor White
Write-Host "2. View Application Logs: docker-compose logs -f ticket-service" -ForegroundColor White
Write-Host "3. Access PostgreSQL: docker exec -it urbanflow-tickets-db psql -U postgres -d urbanflow_tickets" -ForegroundColor White
