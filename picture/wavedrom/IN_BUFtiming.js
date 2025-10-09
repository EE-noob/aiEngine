{signal: [
  {name: 'CLK', wave: 'p....', period: 2},
  {name: 'ics_rd_en', wave: '0.1...0...', data: ['IDLE', 'ACTIVE', 'IDLE']},
  {name: 'ics_rd_addr[4:0]', wave: 'x.3...x...', data: ['ADDR0', 'ADDR1']},
  {name: 'ics_rd_data[127:0]', wave: 'x.....3...', data: ['DATA0', 'DATA1']}
],
config: {hscale: 2},
head: {text: 'IN_BUF读时序（ICS电路上游inut）', tick: 0}}