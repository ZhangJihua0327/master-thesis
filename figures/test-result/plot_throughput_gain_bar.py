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
matplotlib.rcParams["font.size"] = 16
matplotlib.rcParams["axes.labelsize"] = 17
matplotlib.rcParams["xtick.labelsize"] = 16
matplotlib.rcParams["ytick.labelsize"] = 16
matplotlib.rcParams["legend.fontsize"] = 15

import matplotlib.pyplot as plt
import numpy as np

SCRIPT_DIR = Path(__file__).resolve().parent
BENCHMARK_ORDER = ["Courseware", "SmallBank", "TPCC"]
STRATEGY_ORDER = ["SI-SER", "MIAED"]
STRATEGY_COLORS = {
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


def to_gain(values: dict[str, dict[str, float]]) -> dict[str, dict[str, float]]:
    gains: dict[str, dict[str, float]] = {benchmark: {} for benchmark in BENCHMARK_ORDER}
    for benchmark in BENCHMARK_ORDER:
        ser = values[benchmark]["SER"]
        for strategy in STRATEGY_ORDER:
            gains[benchmark][strategy] = (values[benchmark][strategy] - ser) / ser * 100.0
    return gains


def plot_chart(input_name: str, csv_path: Path) -> Path:
    gains = to_gain(load_rows(csv_path))
    positions = np.arange(len(BENCHMARK_ORDER))
    width = 0.28

    fig, ax = plt.subplots(figsize=(7.2, 5.2))
    max_value = max(gains[benchmark][strategy] for benchmark in BENCHMARK_ORDER for strategy in STRATEGY_ORDER)

    for offset_index, strategy in enumerate(STRATEGY_ORDER):
        bar_positions = positions + (offset_index - 0.5) * width
        series = [gains[benchmark][strategy] for benchmark in BENCHMARK_ORDER]
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
                f"{value:.1f}%",
                ha="center",
                va="bottom",
                fontsize=14,
            )

    ax.axhline(0, color="black", linewidth=0.8)
    ax.set_xticks(positions)
    ax.set_xticklabels(BENCHMARK_ORDER)
    ax.set_ylabel("Throughput Gain over SER (%)")
    ax.set_xlabel("Benchmark")
    ax.grid(axis="y", linestyle="--", linewidth=0.6, alpha=0.45)
    ax.set_axisbelow(True)
    ax.legend(
        frameon=False,
        ncol=2,
        loc="lower center",
        bbox_to_anchor=(0.5, 1.03),
        borderaxespad=0.0,
    )
    ax.set_ylim(0, max_value * 1.26)

    output_path = SCRIPT_DIR / f"throughput_gain_{input_name}.pdf"
    fig.tight_layout(rect=(0, 0, 1, 0.90))
    fig.savefig(output_path, format="pdf", bbox_inches="tight")
    plt.close(fig)
    return output_path


def main() -> None:
    for input_name, filename in INPUTS.items():
        output_path = plot_chart(input_name, SCRIPT_DIR / filename)
        print(f"Generated {output_path}")


if __name__ == "__main__":
    main()
