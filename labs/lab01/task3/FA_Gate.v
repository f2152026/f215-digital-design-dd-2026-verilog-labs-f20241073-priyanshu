module FA_Gate(
  input  a,
  input  b,
  input  cin,
  output sum,
  output cout
);

  wire axb, a_and_b, axb_and_cin; //x is xor

  xor #(2) g1 (axb, a, b);
  and #(2) g2 (a_and_b, a, b);
  xor #(2) g3 (sum, axb, cin);
  and #(2) g4 (axb_and_cin, axb, cin);
  or  #(2) g5 (cout, a_and_b, axb_and_cin);

endmodule