# Interest Calculator in TASM Assembly

A 32-bit compound and simple interest calculator written in Turbo Assembler (TASM) for DOS.

## Features
- Simple Interest Calculation
- Compound Interest Calculation
- Login System (Username: root, Password: admin)
- Input Validation (no empty/spaces/invalid characters)
- 32-bit arithmetic for large numbers

## How to Use
1. Login with: root / admin
2. Choose option:
   - 1 = Simple Interest
   - 2 = Compound Interest  
   - 3 = Logout
3. Enter values when prompted
4. View result and return to menu

## Compile & Run
```batch
tasm calc.asm
tlink calc.obj
calc.exe
```

## Note
- Keep the max value to 100_000 for optimal use and to avoid overflowing
