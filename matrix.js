import { columnInputElement, matrix, rowInputElement, submitButton } from "./elements.js";

const rowToPin = {
  1: 17, 2: 18, 3: 19, 4: 20,
  5: 40, 6: 39, 7: 38, 8: 37, 9: 36, 10: 35, 11: 34, 12: 33,
};

const colToPin = {
  1: 5, 2: 6, 3: 7, 4: 8, 5: 25, 6: 26, 7: 27, 8: 28,
  9: 24, 10: 23, 11: 22, 12: 21, 13: 4, 14: 3, 15: 2, 16: 1,
  17: 16, 18: 15, 19: 14, 20: 13, 21: 30, 22: 29, 23: 9, 24: 10, 25: 11, 26: 12,
};

export function rowInput() {
  const row = rowInputElement?.valueAsNumber;
  return Number.isNaN(row) ? -1 : row;
}

export function columnInput() {
  const column = columnInputElement?.valueAsNumber;
  return Number.isNaN(column) ? -1 : column;
}

function showSelection(row, col) {
  document.querySelectorAll(".square.active").forEach((square) => {
    square.classList.remove("active");
  });

  const pins = [rowToPin[row], colToPin[col]].filter(Boolean);

  for (const pin of pins) {
    const square = document.querySelector(`.square[data-pin="${pin}"]`);
    if (square) {
      square.classList.add("active");
    }
  }
}

export function initMatrix() {
  if (matrix) {
    matrix.innerHTML = "";
    for (let pin = 1; pin <= 40; pin += 1) {
      const square = document.createElement("div");
      square.className = "square";
      square.dataset.pin = String(pin);
      matrix.appendChild(square);
    }
  }

  if (!submitButton) {
    return;
  }

  submitButton.addEventListener("click", () => {
    const row = rowInput();
    const column = columnInput();
    console.log(row, column);
    showSelection(row, column);
  });
}
