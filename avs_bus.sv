//////////////////////////////////////////////////////////////////////////////////
// Company : 
// Engineer: Luo Guibin
// 
// Create Date   : 2018/04/05
// Design Name   : 
// Module Name   : 
// Project Name  : 
// Target Devices: 
// Tool Versions : 
// Description   : Avalon bus task 
// 
// Dependencies  : 
// 
// Revision      :
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ns

/// Testbench top module
module avs_tb();
    /// System signals
    logic        clk;
    logic        rst;
    logic [31:0] avs_addr;
    logic [31:0] avs_rd_data;
    logic [31:0] avs_wr_data;
    logic        avs_ren;
    logic        avs_wen;
    logic        avs_rd_valid;

    logic [31:0] data_reg;
    logic [31:0] rd_data;
    
    /// Paramters declaration
    parameter    CLK_100M   =  5;   /// Half period of 100M clock
    parameter    ADDR       = 32'h1234;
    
    
    /// Generate clock
    initial begin
        clk    = 1'b0;
        forever #CLK_100M clk = ~clk;  
    end

    /// import reg address
    import reg_addr_pak::*;

    /// Testbentch stimulation
    initial begin
        rst          = 1'b1;
        avs_addr     = 'd0;
        avs_wr_data  = 'd0;
        avs_rd_data  = 'd0;
        avs_ren      = 1'b0;
        avs_wen      = 1'b0;
        avs_rd_valid = 1'b0;
        data_reg     = 'd0;
        rd_data      = 'd0;
        # 1000 
        rst          = 1'b0;

        /*
        /// Test the avalon slave DUT
        avs_bus_test(REG1_ADDR, 32'h1234);

        avs_bus_test(REG2_ADDR, 32'h5678);

        avs_bus_test(REG3_ADDR, 32'h1324);
        */

        /// Master write
        #40 $display("@%t:Write in main therad: %h", $time, data_reg);
        #50 avs_master_write(REG1_ADDR, 32'h5634);
        #50 avs_master_read(REG1_ADDR, rd_data);
        #60 $display("@%t:After write in main therad: %h", $time, data_reg);
       
        #500
        $display("data register is: %h", data_reg);
        $stop;
    end

    /// 
    initial begin
        fork
            avs_slave_read_respond(REG1_ADDR, data_reg);
            avs_slave_write_respond(REG1_ADDR, data_reg);
        join
        /*
        /// slave wait to be read in a thread
        #10 $display("@%t:Wait read in therad: %h", $time, data_reg);
        #20 avs_slave_read(REG1_ADDR, data_reg);
        #60 $display("@%t:After read in therad: %h", $time, data_reg);
        */
    end

    /// timeout stop
    initial begin
        # 3000;
        $stop;
    end

    /*
    /// Avalon slave interface
    avs_slave_if #
        (
             .WIDTH(32)
            ,.WAIT(2)
        )
        u_avs_slave(
             .clk           (clk          )
            ,.rst           (rst          )
            ,.avs_addr      (avs_addr     )
            ,.avs_rd_data   (avs_rd_data  )
            ,.avs_wr_data   (avs_wr_data  )
            ,.avs_ren       (avs_ren      )
            ,.avs_wen       (avs_wen      )
            ,.avs_rd_valid  (avs_rd_valid )
        );
    */
    //////////////////////////////////////////////////////////////////////////////////
    /// Avalon bus test operation, read after read
    //////////////////////////////////////////////////////////////////////////////////
    task automatic avs_bus_test
        (
             input        logic [31:0] addr
            ,input        logic [31:0] data 
        );

        logic  [31:0] reg_val;

        /// read follewed write
        #100
        avs_master_write(addr, data);
        #100
        avs_master_read(addr, reg_val);

        /// check the result
        if (reg_val == data)
            $display("Register check passed");
        else
            $display("Register check failed");

    endtask

    //////////////////////////////////////////////////////////////////////////////////
    /// Avalon master read
    //////////////////////////////////////////////////////////////////////////////////
    task automatic avs_master_read
        (
             input        logic [31:0] addr
            ,ref          logic [31:0] data
        );

        @ (posedge clk);

        avs_addr = addr;
        avs_ren  = 1'b1;

        @ (posedge clk);
        avs_ren  = 1'b0;

        wait(avs_rd_valid);
        data     = avs_rd_data;

        @ (posedge clk);
        avs_addr = 'd0;
    endtask
    //////////////////////////////////////////////////////////////////////////////////
    /// Avalon master write
    //////////////////////////////////////////////////////////////////////////////////
    task avs_master_write
        (
             input       logic [31:0] addr
            ,input       logic [31:0] data
        );

        @ (posedge clk);
        avs_addr    = addr;
        avs_wen     = 1'b1;
        avs_wr_data = data;

        @ (posedge clk);
        avs_wen     = 1'b0;
        avs_addr    = 'd0;
        avs_wr_data = 'd0;

        @ (posedge clk);
    endtask

    //////////////////////////////////////////////////////////////////////////////////
    /// Avalon slave write response
    //////////////////////////////////////////////////////////////////////////////////    
    task automatic avs_slave_write_respond
        (
             input        logic [31:0] addr
            ,ref          logic [31:0] data
        );

        wait (avs_addr == addr && avs_wen)

        data         = avs_wr_data;  

        @ (posedge clk);
    endtask

    //////////////////////////////////////////////////////////////////////////////////
    /// Avalon slave read response
    //////////////////////////////////////////////////////////////////////////////////    
    task automatic avs_slave_read_respond
        (
             input        logic [31:0] addr
            ,ref          logic [31:0] data
        );

        wait (avs_addr == addr && avs_ren);

        // wait state 2 clk
        repeat(2) @ (posedge clk);

        @ (posedge clk);
        avs_rd_data  = data;
        avs_rd_valid = 1'b1;

        @ (posedge clk);
        avs_rd_valid = 1'b0;
        avs_rd_data  = 'd0;
    endtask
    
endmodule


// end









