format ELF64 executable

;------------------------------------------------
; definitions block
;------------------------------------------------
AF_INET     = 2
SOCK_STREAM = 1
STDOUT      = 1
STDERR      = 2
maxcons     = 5
SOCKADDR_IN_SIZE = 16



;------------------------------------------------
; macro block
;------------------------------------------------
macro socket domain, type, protocol {
    mov rdi, domain
    mov rsi, type
    mov rdx, protocol
    mov rax, 41
    syscall
}
macro write fd, buf, count {
    mov rdi, fd
    mov rsi, buf
    mov rdx, count
    mov rax, 1
    syscall
}
macro exit code {
    mov rdi, code
    mov rax, 60
    syscall
}
macro bind sockfd, addr, addrlen {
    mov rdi, sockfd
    mov rsi, addr
    mov rdx, addrlen
    mov rax, 49
    syscall
}
macro close fd {
    mov rdi, fd
    mov rax, 3
    syscall
}
macro listen fd, backlog {
    mov rdi, fd
    mov rsi, backlog
    mov rax, 50
    syscall
}
macro accept fd, addr, addrlen {
    mov rdi, fd
    mov rsi, addr
    mov rdx, addrlen
    mov rax, 43
    syscall
}



;------------------------------------------------
; code block
;------------------------------------------------
segment readable executable
    entry main
    main:
        ; socket creating
        write STDOUT, start, start_len              ; application start message
        write STDOUT, sockStart, sockStart_len      ; socket message
        socket AF_INET, SOCK_STREAM, 0              ; socket creation func
        cmp rax, 0                                  ; rax(res of socket) == 0 ?
        jl .error                                   ; if(rax < 0) jmp exit
        mov qword [sockfd], rax
        write STDOUT, sock_ok, sock_ok_len          ; else print sock_ok

        ; binding socket
        write STDOUT, bindStart, bindStart_len
        mov word  [servaddr.sin_family], AF_INET
        mov dword [servaddr.sin_addr], 0
        mov word  [servaddr.sin_port], 14619        ; 6969 because i dont want to create htons analogue
        bind [sockfd], servaddr.sin_family, servaddr_len
        cmp rax, 0
        jl .error

        ; listen socket
        listen [sockfd], maxcons
        cmp rax, 0
        jl .error
        jmp .accept_loop

        ; accept socket
        .accept_loop:
            accept [sockfd], cliaddr.sin_family, clientaddr_len_ptr
            cmp rax, 0
            jl .error

            ; accept result to connfd
            mov qword [connfd], rax
            write [connfd], http_header, http_header_len
            write [connfd], page, page_len

            write STDOUT, ok, ok_len
            close [connfd]
            jmp .accept_loop

        close [sockfd]
        exit 0                                      ; exit(0)
        .error:
            write STDERR, error_msg, error_msg_len
            close [connfd]
            close [sockfd]
            exit -1



;------------------------------------------------
; data block
;------------------------------------------------
segment readable writable

    struc servaddr_in
    {
        .sin_family dw 0
        .sin_port   dw 0
        .sin_addr   dd 0
        .sin_zero   dq 0
    }

    ;; usefull stuff
    sockfd   dq -1
    connfd   dq -1
    servaddr servaddr_in
    servaddr_len = $ - servaddr

    cliaddr  servaddr_in
    cliaddr_len = $ - cliaddr
    clientaddr_len_ptr dq cliaddr_len

    ;; messages
    start db "INFO: starting webserver!", 10
    start_len = $ - start
    sockStart db "INFO: creating socket", 10
    sockStart_len = $ - sockStart
    sock_ok db "INFO: socket succesfuly created", 10
    sock_ok_len = $ - sock_ok
    bindStart db "INFO: Binding the socket...", 10
    bindStart_len = $ - bindStart
    error_msg db "ERROR: Error!", 10
    error_msg_len = $ - error_msg
    ok db "INFO: OK!", 10
    ok_len = $ - ok

    http_header db 'HTTP/1.1 200 OK',13,10
            db 'Content-Type: text/html; charset=UTF-8',13,10
            db 'Connection: close',13,10
            db 13,10
    http_header_len = $ - http_header

    page:
        file 'index.html'
    page_end:

    page_len = page_end - page























