// cla64_blocked.v
// A practical 64-bit adder: sixteen 4-bit CLA blocks (your cla4.v),
// chained by feeding block k's carry-out into block (k+1)'s carry-in --
// the same instantiate-and-chain pattern as Task 2's ripple adder, just
// using 4-bit CLA blocks instead of single full adders.
//
// TODO: instantiate 16 cla4 blocks, named block0..block15, e.g.:
//   cla4 block0 (.a(a[3:0]),    .b(b[3:0]),    .cin(cin),  .sum(sum[3:0]),    .cout(c[1]));
//   cla4 block1 (.a(a[7:4]),    .b(b[7:4]),    .cin(c[1]), .sum(sum[7:4]),    .cout(c[2]));
//   ...
//   cla4 block15(.a(a[63:60]),  .b(b[63:60]),  .cin(c[15]),.sum(sum[63:60]),  .cout(cout));
// 1. The Leaf: Modified 4-bit CLA
module cla4_leaf(
  input  [3:0] a,
  input  [3:0] b,
  input        cin,
  output [3:0] sum,
  output       P_block,
  output       G_block
);
  wire [3:0] p, g;
  wire c1, c2, c3;

  assign #(2) p = a ^ b;
  assign #(2) g = a & b;

  assign #(2) c1 = g[0] | (p[0] & cin);
  assign #(2) c2 = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
  assign #(2) c3 = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & cin);

  assign #(2) sum = p ^ {c3, c2, c1, cin};

  assign #(2) P_block = p[3] & p[2] & p[1] & p[0];
  assign #(2) G_block = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
endmodule

// 2. The Lookahead Carry Unit (LCU)
module lcu(
  input  [3:0] P,
  input  [3:0] G,
  input        Cin,
  output       C1, 
  output       C2, 
  output       C3,
  output       P_group,
  output       G_group
);
  assign #(2) C1 = G[0] | (P[0] & Cin);
  assign #(2) C2 = G[1] | (P[1] & G[0]) | (P[1] & P[0] & Cin);
  assign #(2) C3 = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) | (P[2] & P[1] & P[0] & Cin);

  assign #(2) P_group = P[3] & P[2] & P[1] & P[0];
  assign #(2) G_group = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0]);
endmodule

// 3. The 16-bit Sub-Block (Groups four 4-bit leaves + one LCU)
module cla16_block(
  input  [15:0] a,
  input  [15:0] b,
  input         cin,
  output [15:0] sum,
  output        P_group,
  output        G_group
);
  wire [3:0] P_blk, G_blk;
  wire c4, c8, c12; 

  lcu lcu_mid (
    .P(P_blk), .G(G_blk), .Cin(cin),
    .C1(c4), .C2(c8), .C3(c12),
    .P_group(P_group), .G_group(G_group)
  );

  cla4_leaf b0 (.a(a[3:0]),   .b(b[3:0]),   .cin(cin), .sum(sum[3:0]),   .P_block(P_blk[0]), .G_block(G_blk[0]));
  cla4_leaf b1 (.a(a[7:4]),   .b(b[7:4]),   .cin(c4),  .sum(sum[7:4]),   .P_block(P_blk[1]), .G_block(G_blk[1]));
  cla4_leaf b2 (.a(a[11:8]),  .b(b[11:8]),  .cin(c8),  .sum(sum[11:8]),  .P_block(P_blk[2]), .G_block(G_blk[2]));
  cla4_leaf b3 (.a(a[15:12]), .b(b[15:12]), .cin(c12), .sum(sum[15:12]), .P_block(P_blk[3]), .G_block(G_blk[3]));
endmodule

// 4. The Top Level 64-bit CLA (Groups four 16-bit blocks + the Top LCU)
module cla64_blocked(
  input  [63:0] a,
  input  [63:0] b,
  input         cin,
  output [63:0] sum,
  output        cout
);
  wire [3:0] P_grp, G_grp;
  wire c16, c32, c48;
  wire P_top, G_top;

  lcu lcu_top (
    .P(P_grp), .G(G_grp), .Cin(cin),
    .C1(c16), .C2(c32), .C3(c48),
    .P_group(P_top), .G_group(G_top)
  );

  cla16_block g0 (.a(a[15:0]),  .b(b[15:0]),  .cin(cin), .sum(sum[15:0]),  .P_group(P_grp[0]), .G_group(G_grp[0]));
  cla16_block g1 (.a(a[31:16]), .b(b[31:16]), .cin(c16), .sum(sum[31:16]), .P_group(P_grp[1]), .G_group(G_grp[1]));
  cla16_block g2 (.a(a[47:32]), .b(b[47:32]), .cin(c32), .sum(sum[47:32]), .P_group(P_grp[2]), .G_group(G_grp[2]));
  cla16_block g3 (.a(a[63:48]), .b(b[63:48]), .cin(c48), .sum(sum[63:48]), .P_group(P_grp[3]), .G_group(G_grp[3]));

  // The final carry out for the entire 64-bit adder
  assign #(2) cout = G_top | (P_top & cin);

endmodule
