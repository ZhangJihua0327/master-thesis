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
matplotlib.rcParams["font.size"] = 15
matplotlib.rcParams["axes.labelsize"] = 16
matplotlib.rcParams["xtick.labelsize"] = 15
matplotlib.rcParams["ytick.labelsize"] = 15
matplotlib.rcParams["legend.fontsize"] = 14

import matplotlib.pyplot as plt
import numpy as np

SCRIPT_DIR = Path(__file__).resolve().parent
BENCHMARK_ORDER = ["Courseware", "SmallBank", "TPCC"]
DEPLOY_ORDER = ["single-az", "pair-az"]
STRATEGY_ORDER = ["SER", "MIAED"]
DEPLOY_SUFFIX = {"single-az": "single-az", "pair-az": "pair-az"}
STRATEGY_COLORS = {"SER": "#4E79A7", "MIAED": "#59A14F"}


def parse_percent(value: str) -> float:
    return float(value.strip().rstrip("%"))


def load_rows(csv_path: Path) -> dict[str, dict[str, dict[str, float]]]:
    rows: dict[str, dict[str, dict[str, float]]] = {
        benchmark: {deploy: {} for deploy in DEPLOY_ORDER} for benchmark in BENCHMARK_ORDER
    }
    with csv_path.open("r", newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            rows[row["benchmark"]][row["deploy-env"]][row["strategy"]] = parse_percent(row["abort_rt"])
    return rows


def plot_chart(values: dict[str, dict[str, dict[str, float]]], deploy: str) -> Path:
    positions = np.arange(len(BENCHMARK_ORDER))
    width = 0.24
    fig, ax = plt.subplots(figsize=(5.8, 4.8))
    max_value = max(values[benchmark][deploy][strategy] for benchmark in BENCHMARK_ORDER for strategy in STRATEGY_ORDER)
    label_offset = max_value * 0.015

    for offset_index, strategy in enumerate(STRATEGY_ORDER):
        bar_positions = positions + (offset_index - 0.5) * width
        series = [values[benchmark][deploy][strategy] for benchmark in BENCHMARK_ORDER]
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
                value + label_offset,
                f"{value:.1f}%",
                ha="center",
                va="bottom",
                fontsize=14,
                rotation=90,
                clip_on=False,
            )

    ax.set_xticks(positions)
    ax.set_xticklabels(BENCHMARK_ORDER)
    ax.set_ylabel("Abort Rate (%)")
    ax.grid(axis="y", linestyle="--", linewidth=0.6, alpha=0.45)
    ax.set_axisbelow(True)
    ax.set_ylim(0, max_value * 1.45)
    ax.legend(
        frameon=False,
        ncol=2,
        loc="lower center",
        bbox_to_anchor=(0.5, 1.03),
        borderaxespad=0.0,
    )

    output_path = SCRIPT_DIR / f"abort_rate_{DEPLOY_SUFFIX[deploy]}.pdf"
    fig.tight_layout(rect=(0, 0, 1, 0.90))
    fig.savefig(output_path, format="pdf", bbox_inches="tight")
    plt.close(fig)
    return output_path


def main() -> None:
    values = load_rows(SCRIPT_DIR / "bench_txn_abort_rt.csv")
    for deploy in DEPLOY_ORDER:
        output_path = plot_chart(values, deploy)
        print(f"Generated {output_path}")


if __name__ == "__main__":
    main()
