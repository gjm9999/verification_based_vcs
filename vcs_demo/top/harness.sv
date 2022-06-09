`define module_urandom_define \
    string   path_str; \
    initial  path_str = $psprintf(path_str, "%m"); \
    \
    function integer urandom; \
        integer seed, i; \
        begin \
            seed = $urandom(); \
            for(i=path_str.len; i>=0; i=i-1)begin \
                seed = seed ^ path_str.getc(i); \
                seed = $urandom(seed); \
            end \
            urandom = $abs(seed); \
        end \
    endfunction \
    function integer urandom_range(); \
        input integer min, max; \
        integer seed, i; \
        begin \
            seed = $urandom(); \
            for(i=path_str.len; i>=0; i=i-1)begin \
                seed = seed ^ path_str.getc(i); \
                seed = $urandom(seed); \
            end \
            urandom_range = min + $abs(seed % (max - min)); \
        end \
    endfunction

module rand_test();
    int a, b;
    
    `module_urandom_define;
    
    initial begin
        for (int xx=0; xx<3; xx++)begin
            a = urandom();
            b = urandom_range(10,200);
            $display("%m.a = %0d, b = %0d", a, b);
            #100ns;
        end
    end
endmodule

module harness();
    
    rand_test U_A();
    rand_test U_B();
    rand_test U_C();

    initial #1000ns $finish;
endmodule
