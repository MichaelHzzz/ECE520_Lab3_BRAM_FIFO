from pathlib import Path

# Find the lab folder relative to this script.
lab_dir = Path(__file__).resolve().parent.parent
output_file = lab_dir / "sim" / "input_data.txt"

# Four test patterns followed by values 0 through 31.
test_data = [0xFFFF, 0x0000, 0xAAAA, 0x5555]
test_data += list(range(32))

with output_file.open("w") as file:
    for value in test_data:
        file.write(f"{value:04X}\n")

print("Generated 36 words in sim/input_data.txt")