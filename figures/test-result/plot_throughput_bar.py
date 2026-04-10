from __future__ import annotations

import csv
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
matplotlib.rcParams["figure.dpi"] = 150
matplotlib.rcParams["savefig.dpi"] = 150
matplotlib.rcParams["font.family"] = "DejaVu Sans"
matplotlib.rcParams["pdf.fonttype"] = 42
matplotlib.rcParams["ps.fonttype"] = 42
matplotlib.rcParams["axes.spines.top"] = False
matplotlib.rcParams["axes.spines.right"] = False
matplotlib.rcParams["font.size"] = 14
matplotlib.rcParams["axes.labelsize"] = 15
matplotlib.rcParams["xtick.labelsize"] = 14
matplotlib.rcParams["ytick.labelsize"] = 14
matplotlib.rcParams["legend.fontsize"] = 13

import matplotlib.pyplot as plt
import numpy as np

SCRIPT_DIR = Path(__file__).resolve().parent
BENCHMARK_ORDER = ["Courseware", "SmallBank", "TPCC"]
STRATEGY_ORDER = ["SER", "SI-SER", "MIAED"]
STRATEGY_COLORS = {
    "SER": "#4E79A7",
    "SI-SER": "#F28E2B",
    "MIAED": "#59A14F",
}
INPUTS = {
    "single-az": "bench_strategy_single_az_summary.csv",
    "pair-az": "bench_strategy_pair_az_summary.csv",
}


def load_rows(csv_path: Path) -> dict[str, dict[str, float]]:
    rows: dict[str, dict[str, float]] = {benchmark: {} for benchmark in BENCHMARK_ORDER}
    with csv_path.open("r", newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            rows[row["benchmark"]][row["strategy"]] = float(row["mean_throughput_tx_per_sec"])
    return rows


def plot_chart(input_name: str, csv_path: Path) -> Path:
    values = load_rows(csv_path)
    positions = np.arange(len(BENCHMARK_ORDER))
    width = 0.22

    fig, ax = plt.subplots(figsize=(8.8, 5.2))
    max_value = max(values[benchmark][strategy] for benchmark in BENCHMARK_ORDER for strategy in STRATEGY_ORDER)

    for offset_index, strategy in enumerate(STRATEGY_ORDER):
        bar_positions = positions + (offset_index - 1) * width
        series = [values[benchmark][strategy] for benchmark in BENCHMARK_ORDER]
        bars = ax.bar(
            bar_positions,
            series,
            width=width,
            label=strategy,
            color=STRATEGY_COLORS[strategy],
            edgecolor="black",
            linewidth=0.6,
        )
        for bar, value in zip(bars, series):
            ax.text(
                bar.get_x() + bar.get_width() / 2,
                value + max_value * 0.015,
                f"{value:.1f}",
                ha="center",
                va="bottom",
                fontsize=13,
            )

    ax.set_xticks(positions)
    ax.set_xticklabels(BENCHMARK_ORDER)
    ax.set_ylabel("Throughput (tx/s)")
    ax.set_xlabel("Benchmark")
    ax.grid(axis="y", linestyle="--", linewidth=0.6, alpha=0.45)
    ax.set_axisbelow(True)
    ax.legend(frameon=False, ncol=1, loc="lower left", bbox_to_anchor=(1.02, 0.02), borderaxespad=0.0)
    ax.set_ylim(0, max_value * 1.22)

    output_path = SCRIPT_DIR / f"throughput_{input_name}.pdf"
    fig.tight_layout(rect=(0, 0, 0.88, 1))
    fig.savefig(output_path, format="pdf", bbox_inches="tight")
    plt.close(fig)
    return output_path


def main() -> None:
    for input_name, filename in INPUTS.items():
        output_path = plot_chart(input_name, SCRIPT_DIR / filename)
        print(f"Generated {output_path}")


if __name__ == "__main__":
    main()
