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

SCRIPT_DIR = Path(__file__).resolve().parent
CSV_PATH = SCRIPT_DIR / "bench_stress_test.csv"
OUTPUT_PATH = SCRIPT_DIR / "stress_test_resource_latency.pdf"

CPU_COLOR = "#4E79A7"
MEMORY_COLOR = "#59A14F"
LATENCY_COLOR = "#E15759"


def load_series(csv_path: Path) -> tuple[list[float], list[float], list[float], list[float]]:
    times: list[float] = []
    cpu_usage: list[float] = []
    memory_usage: list[float] = []
    tx_latency: list[float] = []

    with csv_path.open("r", newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            times.append(float(row["Time_s"]))
            cpu_usage.append(float(row["CPU_Usage_%"]))
            memory_usage.append(float(row["Memory_Usage_%"]))
            tx_latency.append(float(row["Tx_Latency_ms"]))

    return times, cpu_usage, memory_usage, tx_latency


def plot_chart(times: list[float], cpu_usage: list[float], memory_usage: list[float], tx_latency: list[float]) -> Path:
    fig, ax_left = plt.subplots(figsize=(7.8, 5.8))
    ax_right = ax_left.twinx()

    line_cpu, = ax_left.plot(
        times,
        cpu_usage,
        color=CPU_COLOR,
        linewidth=2.0,
        marker="o",
        markersize=4.0,
        label="CPU usage",
    )
    line_memory, = ax_left.plot(
        times,
        memory_usage,
        color=MEMORY_COLOR,
        linewidth=2.0,
        marker="s",
        markersize=4.0,
        label="Memory usage",
    )
    line_latency, = ax_right.plot(
        times,
        tx_latency,
        color=LATENCY_COLOR,
        linewidth=2.2,
        marker="D",
        markersize=4.2,
        label="Transaction latency",
    )

    ax_left.set_xlabel("Time (s)")
    ax_left.set_ylabel("CPU / Memory Usage (%)")
    ax_right.set_ylabel("Transaction Latency (ms)")
    ax_left.set_xlim(min(times), max(times))
    ax_left.set_ylim(0, 100)
    ax_right.set_ylim(0, max(tx_latency) + 1.0)
    ax_left.grid(axis="both", linestyle="--", linewidth=0.6, alpha=0.45)
    ax_left.set_axisbelow(True)

    handles = [line_cpu, line_memory, line_latency]
    labels = [handle.get_label() for handle in handles]
    ax_left.legend(
        handles,
        labels,
        frameon=False,
        ncol=3,
        loc="lower left",
        bbox_to_anchor=(0.0, 1.03),
        borderaxespad=0.0,
    )

    fig.tight_layout(rect=(0, 0, 1, 0.92))
    fig.savefig(OUTPUT_PATH, format="pdf", bbox_inches="tight")
    plt.close(fig)
    return OUTPUT_PATH


def main() -> None:
    times, cpu_usage, memory_usage, tx_latency = load_series(CSV_PATH)
    output_path = plot_chart(times, cpu_usage, memory_usage, tx_latency)
    print(f"Generated {output_path}")


if __name__ == "__main__":
    main()
