# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "marimo",
#     "numpy",
#     "pandas",
#     "plotly",
#     "scipy",
# ]
# ///

import marimo

__generated_with = "0.11.0"
app = marimo.App(width="full")


@app.cell
def _():
    import glob
    import os
    import io

    import marimo as mo
    import numpy as np
    import pandas as pd
    import plotly.graph_objects as go
    from plotly.subplots import make_subplots
    from scipy import linalg

    SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
    DEFAULT_CSV_DIR = os.path.join(SCRIPT_DIR, "csv_files")

    return (
        DEFAULT_CSV_DIR,
        SCRIPT_DIR,
        glob,
        go,
        io,
        linalg,
        make_subplots,
        mo,
        np,
        os,
        pd,
    )


@app.cell
def _(mo):
    mo.md(
        r"""
        # 🔢 CPD Factor Matrices Calculation Only

        This Marimo app calculates and displays the **Unified CPD Factor Matrix View** for the
        **LIQUID** and **FCC** Gibbs-energy tensors.

        \[
        G(i,j,k,t) \approx \sum_{r=1}^{R} \lambda_r A_{ir}B_{jr}C_{kr}D_{tr}
        \]
        """
    )
    return


@app.cell
def _(glob, linalg, make_subplots, np, os, pd, go):
    def load_all_data(csv_dir: str) -> pd.DataFrame:
        files = sorted(glob.glob(os.path.join(csv_dir, "Gibbs_*K.csv")))
        if not files:
            raise FileNotFoundError(
                f"No Gibbs CSV files found in: {csv_dir}\n"
                "Expected files such as Gibbs_300K.csv, Gibbs_700K.csv, Gibbs_800K.csv, ..."
            )

        frames = []
        skipped = []
        for path in files:
            name = os.path.basename(path)
            try:
                temperature = int(name.replace("Gibbs_", "").replace("K.csv", ""))
                tmp = pd.read_csv(
                    path,
                    usecols=["Co", "Cr", "Fe", "Ni", "G_LIQ", "G_FCC"],
                )
                tmp["T"] = temperature
                frames.append(tmp)
            except Exception as exc:
                skipped.append(f"{name}: {exc}")

        if not frames:
            raise ValueError("No valid Gibbs CSV files could be loaded.")

        df = pd.concat(frames, ignore_index=True)
        for column in ["Co", "Cr", "Fe", "Ni", "G_LIQ", "G_FCC", "T"]:
            df[column] = pd.to_numeric(df[column], errors="coerce")
        df = df.dropna(subset=["Co", "Cr", "Fe", "Ni", "G_LIQ", "G_FCC", "T"]).copy()
        df["T"] = df["T"].astype(int)
        df.attrs["skipped_files"] = skipped
        return df


    def build_tensor_data(df: pd.DataFrame) -> dict:
        co_vals = np.array(sorted(df["Co"].unique()), dtype=float)
        cr_vals = np.array(sorted(df["Cr"].unique()), dtype=float)
        fe_vals = np.array(sorted(df["Fe"].unique()), dtype=float)
        T_vals = np.array(sorted(df["T"].unique()), dtype=float)

        n_co = len(co_vals)
        n_cr = len(cr_vals)
        n_fe = len(fe_vals)
        n_T = len(T_vals)

        co_to_idx = {round(float(value), 4): idx for idx, value in enumerate(co_vals)}
        cr_to_idx = {round(float(value), 4): idx for idx, value in enumerate(cr_vals)}
        fe_to_idx = {round(float(value), 4): idx for idx, value in enumerate(fe_vals)}
        T_to_idx = {int(value): idx for idx, value in enumerate(T_vals)}

        G_LIQ = np.full((n_co, n_cr, n_fe, n_T), np.nan, dtype=np.float64)
        G_FCC = np.full((n_co, n_cr, n_fe, n_T), np.nan, dtype=np.float64)

        for row in df.itertuples(index=False):
            i = co_to_idx.get(round(float(row.Co), 4))
            j = cr_to_idx.get(round(float(row.Cr), 4))
            k = fe_to_idx.get(round(float(row.Fe), 4))
            t = T_to_idx.get(int(row.T))
            if i is not None and j is not None and k is not None and t is not None:
                G_LIQ[i, j, k, t] = float(row.G_LIQ)
                G_FCC[i, j, k, t] = float(row.G_FCC)

        return {
            "G_LIQ": G_LIQ,
            "G_FCC": G_FCC,
            "dims": (n_co, n_cr, n_fe, n_T),
            "co_vals": co_vals,
            "cr_vals": cr_vals,
            "fe_vals": fe_vals,
            "T_vals": T_vals,
            "valid_count": int(np.isfinite(G_LIQ).sum()),
        }


    def normalize_tensor(tensor: np.ndarray):
        finite = np.isfinite(tensor)
        if finite.sum() == 0:
            raise ValueError("Tensor contains no finite Gibbs-energy values.")
        mean = float(np.nanmean(tensor))
        std = float(np.nanstd(tensor))
        if not np.isfinite(std) or std < 1e-12:
            std = 1.0
        return (tensor - mean) / std, mean, std


    def unfold_tensor(tensor: np.ndarray, mode: int) -> np.ndarray:
        if mode == 0:
            return tensor.reshape(tensor.shape[0], -1)
        if mode == 1:
            return tensor.transpose(1, 0, 2, 3).reshape(tensor.shape[1], -1)
        if mode == 2:
            return tensor.transpose(2, 0, 1, 3).reshape(tensor.shape[2], -1)
        if mode == 3:
            return tensor.transpose(3, 0, 1, 2).reshape(tensor.shape[3], -1)
        raise ValueError("mode must be 0, 1, 2, or 3")


    def cpd_als_4d_factor_only(
        tensor: np.ndarray,
        rank: int,
        max_iter: int = 100,
        tol: float = 1e-6,
    ):
        I, J, K, L = tensor.shape
        mask = ~np.isnan(tensor)
        X = np.where(mask, tensor, 0.0)

        if L == 31:
            T_vals_physical = np.array(list(range(700, 3701, 100)))
            T_mean = np.mean(T_vals_physical)
            T_std = np.std(T_vals_physical)
            T_norm = (T_vals_physical - T_mean) / (T_std + 1e-12)
            D = np.zeros((L, rank))
            D[:, 0] = 1.0
            if rank >= 2:
                D[:, 1] = T_norm
            if rank >= 3:
                D[:, 2] = (T_norm**2 - 1.0) * 0.5
            if rank >= 4:
                D[:, 3] = np.tanh(2.0 * T_norm) - np.mean(np.tanh(2.0 * T_norm))
            if rank > 4:
                D[:, 4:] = np.random.rand(L, rank - 4) * 0.01
        else:
            D = np.random.rand(L, rank) * 0.1

        X_unfolded = unfold_tensor(X, mode=0)
        try:
            U, svals, _ = linalg.svd(X_unfolded, full_matrices=False)
            A = U[:, :rank] * np.sqrt(svals[:rank])
        except Exception:
            A = np.random.rand(I, rank) * 0.1

        B = np.random.rand(J, rank) * 0.1
        C = np.random.rand(K, rank) * 0.1
        prev_error = np.inf
        error = np.inf

        for iteration in range(max_iter):
            BCD = np.zeros((J * K * L, rank))
            for r in range(rank):
                BCD[:, r] = np.kron(np.kron(D[:, r], C[:, r]), B[:, r])
            X_flat = X.reshape(I, -1)
            mask_flat = mask.reshape(I, -1)
            for i in range(I):
                valid = mask_flat[i, :]
                if np.sum(valid) > rank:
                    A[i, :] = linalg.lstsq(BCD[valid, :], X_flat[i, valid])[0]
            A = A / (np.linalg.norm(A, axis=0) + 1e-12)

            ACD = np.zeros((I * K * L, rank))
            for r in range(rank):
                ACD[:, r] = np.kron(np.kron(D[:, r], C[:, r]), A[:, r])
            X_flat = X.transpose(1, 0, 2, 3).reshape(J, -1)
            mask_flat = mask.transpose(1, 0, 2, 3).reshape(J, -1)
            for j in range(J):
                valid = mask_flat[j, :]
                if np.sum(valid) > rank:
                    B[j, :] = linalg.lstsq(ACD[valid, :], X_flat[j, valid])[0]
            B = B / (np.linalg.norm(B, axis=0) + 1e-12)

            ABD = np.zeros((I * J * L, rank))
            for r in range(rank):
                ABD[:, r] = np.kron(np.kron(D[:, r], B[:, r]), A[:, r])
            X_flat = X.transpose(2, 0, 1, 3).reshape(K, -1)
            mask_flat = mask.transpose(2, 0, 1, 3).reshape(K, -1)
            for k in range(K):
                valid = mask_flat[k, :]
                if np.sum(valid) > rank:
                    C[k, :] = linalg.lstsq(ABD[valid, :], X_flat[k, valid])[0]
            C = C / (np.linalg.norm(C, axis=0) + 1e-12)

            ABC = np.zeros((I * J * K, rank))
            for r in range(rank):
                ABC[:, r] = np.kron(np.kron(C[:, r], B[:, r]), A[:, r])
            X_flat = X.transpose(3, 0, 1, 2).reshape(L, -1)
            mask_flat = mask.transpose(3, 0, 1, 2).reshape(L, -1)
            for t in range(L):
                valid = mask_flat[t, :]
                if np.sum(valid) > rank:
                    D[t, :] = linalg.lstsq(ABC[valid, :], X_flat[t, valid])[0]
            D = D / (np.linalg.norm(D, axis=0) + 1e-12)

            if iteration == 0 or (iteration + 1) % 5 == 0 or iteration == max_iter - 1:
                recon = np.zeros_like(X)
                for r in range(rank):
                    outer = np.outer(A[:, r], np.kron(np.kron(D[:, r], C[:, r]), B[:, r]))
                    recon += outer.reshape(I, J, K, L)
                residual = (tensor - recon)[mask]
                error = float(np.sqrt(np.mean(residual**2))) if len(residual) else np.inf
                if abs(prev_error - error) < tol:
                    break
                prev_error = error

        lam = np.ones(rank)
        for r in range(rank):
            lam[r] = (
                np.linalg.norm(A[:, r])
                * np.linalg.norm(B[:, r])
                * np.linalg.norm(C[:, r])
                * np.linalg.norm(D[:, r])
            )

        return A, B, C, D, lam, error


    def run_cpd_pair(tdt_data: dict, rank: int, max_iter: int) -> dict:
        tensor_liq, _, _ = normalize_tensor(tdt_data["G_LIQ"])
        tensor_fcc, _, _ = normalize_tensor(tdt_data["G_FCC"])

        A_liq, B_liq, C_liq, D_liq, lam_liq, err_liq = cpd_als_4d_factor_only(
            tensor_liq,
            rank,
            max_iter=max_iter,
            tol=1e-5,
        )
        A_fcc, B_fcc, C_fcc, D_fcc, lam_fcc, err_fcc = cpd_als_4d_factor_only(
            tensor_fcc,
            rank,
            max_iter=max_iter,
            tol=1e-5,
        )

        return {
            "rank": rank,
            "A_liq": A_liq,
            "B_liq": B_liq,
            "C_liq": C_liq,
            "D_liq": D_liq,
            "lam_liq": lam_liq,
            "err_liq": err_liq,
            "A_fcc": A_fcc,
            "B_fcc": B_fcc,
            "C_fcc": C_fcc,
            "D_fcc": D_fcc,
            "lam_fcc": lam_fcc,
            "err_fcc": err_fcc,
        }


    def factor_matrices_to_long_csv(
        A,
        B,
        C,
        D,
        lam,
        co_vals,
        cr_vals,
        fe_vals,
        T_vals,
        phase="LIQUID",
        R=6,
    ) -> pd.DataFrame:
        co_arr = np.asarray(co_vals, dtype=float)
        cr_arr = np.asarray(cr_vals, dtype=float)
        fe_arr = np.asarray(fe_vals, dtype=float)
        T_arr = np.asarray(T_vals, dtype=float)
        R_eff = min(int(R), len(lam), A.shape[1], B.shape[1], C.shape[1], D.shape[1])

        blocks = [
            ("A", "Co", "x_Co", co_arr, A, "λ·A"),
            ("B", "Cr", "x_Cr", cr_arr, B, "λ·B"),
            ("C", "Fe", "x_Fe", fe_arr, C, "λ·C"),
            ("D", "Temperature", "Temperature_K", T_arr, D, "λ·D"),
        ]

        rows = []
        for matrix_name, variable, x_label, x_values, factor_matrix, y_label in blocks:
            for r in range(R_eff):
                factor_values = factor_matrix[:, r]
                plotted_values = lam[r] * factor_values
                for x_value, raw_y, plotted_y in zip(x_values, factor_values, plotted_values):
                    rows.append(
                        {
                            "phase": phase,
                            "matrix": matrix_name,
                            "variable": variable,
                            "x_label": x_label,
                            "x_value": float(x_value),
                            "component": f"r={r + 1}",
                            "component_index": r + 1,
                            "lambda": float(lam[r]),
                            "factor_value": float(raw_y),
                            "plotted_value": float(plotted_y),
                            "y_label": y_label,
                        }
                    )

        return pd.DataFrame(rows)


    def factor_matrices_to_wide_csv(long_df: pd.DataFrame) -> pd.DataFrame:
        if long_df.empty:
            return long_df.copy()
        wide = long_df.pivot_table(
            index=["phase", "matrix", "variable", "x_label", "x_value", "y_label"],
            columns="component",
            values="plotted_value",
            aggfunc="first",
        ).reset_index()
        wide.columns.name = None
        return wide


    def plot_unified_factor_matrices(
        A,
        B,
        C,
        D,
        lam,
        co_vals,
        cr_vals,
        fe_vals,
        T_vals,
        phase="LIQUID",
        R=6,
    ):
        co_arr = np.asarray(co_vals, dtype=float)
        cr_arr = np.asarray(cr_vals, dtype=float)
        fe_arr = np.asarray(fe_vals, dtype=float)
        T_arr = np.asarray(T_vals, dtype=float)
        R_eff = min(int(R), len(lam), A.shape[1], B.shape[1], C.shape[1], D.shape[1])
        colors = [
            "#e74c3c",
            "#2980b9",
            "#27ae60",
            "#f39c12",
            "#9b59b6",
            "#1abc9c",
            "#34495e",
            "#e67e22",
        ]

        fig = make_subplots(
            rows=2,
            cols=2,
            subplot_titles=(
                f"A: Co factor (λ·A) — {phase}",
                f"B: Cr factor (λ·B) — {phase}",
                f"C: Fe factor (λ·C) — {phase}",
                f"D: Temperature factor (λ·D) — {phase}",
            ),
            vertical_spacing=0.12,
            horizontal_spacing=0.10,
            specs=[
                [{"type": "scatter"}, {"type": "scatter"}],
                [{"type": "scatter"}, {"type": "scatter"}],
            ],
        )

        for r in range(R_eff):
            color = colors[r % len(colors)]
            fig.add_trace(
                go.Scatter(
                    x=co_arr,
                    y=lam[r] * A[:, r],
                    mode="lines+markers",
                    name=f"r={r + 1}",
                    line={"color": color, "width": 2},
                    marker={"size": 5},
                    legendgroup=f"r{r + 1}",
                    showlegend=True,
                ),
                row=1,
                col=1,
            )
            fig.add_trace(
                go.Scatter(
                    x=cr_arr,
                    y=lam[r] * B[:, r],
                    mode="lines+markers",
                    name=f"r={r + 1}",
                    line={"color": color, "width": 2},
                    marker={"size": 5},
                    legendgroup=f"r{r + 1}",
                    showlegend=False,
                ),
                row=1,
                col=2,
            )
            fig.add_trace(
                go.Scatter(
                    x=fe_arr,
                    y=lam[r] * C[:, r],
                    mode="lines+markers",
                    name=f"r={r + 1}",
                    line={"color": color, "width": 2},
                    marker={"size": 5},
                    legendgroup=f"r{r + 1}",
                    showlegend=False,
                ),
                row=2,
                col=1,
            )
            fig.add_trace(
                go.Scatter(
                    x=T_arr,
                    y=lam[r] * D[:, r],
                    mode="lines+markers",
                    name=f"r={r + 1}",
                    line={"color": color, "width": 2},
                    marker={"size": 6},
                    legendgroup=f"r{r + 1}",
                    showlegend=False,
                    hovertemplate="Temperature=%{x:.0f} K<br>λ·D=%{y:.6g}<extra></extra>",
                ),
                row=2,
                col=2,
            )

        fig.update_xaxes(title_text="x_Co", row=1, col=1)
        fig.update_xaxes(title_text="x_Cr", row=1, col=2)
        fig.update_xaxes(title_text="x_Fe", row=2, col=1)
        fig.update_xaxes(title_text="Temperature (K)", row=2, col=2)
        fig.update_yaxes(title_text="λ·A", row=1, col=1)
        fig.update_yaxes(title_text="λ·B", row=1, col=2)
        fig.update_yaxes(title_text="λ·C", row=2, col=1)
        fig.update_yaxes(title_text="λ·D", row=2, col=2)
        fig.update_layout(
            height=900,
            title_text=f"Unified CPD Factor Matrices — {phase} Phase (R={R_eff})",
            legend={
                "orientation": "h",
                "yanchor": "bottom",
                "y": 1.02,
                "xanchor": "center",
                "x": 0.5,
                "title": "Component",
            },
            template="plotly_white",
        )
        return fig

    return (
        build_tensor_data,
        factor_matrices_to_long_csv,
        factor_matrices_to_wide_csv,
        load_all_data,
        plot_unified_factor_matrices,
        run_cpd_pair,
    )


@app.cell
def _(DEFAULT_CSV_DIR, mo):
    csv_dir_input = mo.ui.text(
        value=DEFAULT_CSV_DIR,
        label="CSV folder",
        full_width=True,
    )
    rank_slider = mo.ui.slider(
        start=1,
        stop=12,
        step=1,
        value=6,
        label="CP rank R",
    )
    max_iter_slider = mo.ui.slider(
        start=10,
        stop=300,
        step=10,
        value=150,
        label="ALS iterations",
    )
    run_cpd_button = mo.ui.run_button(
        label="🚀 Run Factor Matrix CPD for LIQUID and FCC"
    )

    controls_panel = mo.vstack(
        [
            mo.md("## Controls"),
            csv_dir_input,
            rank_slider,
            max_iter_slider,
            run_cpd_button,
        ]
    )
    controls_panel
    return csv_dir_input, max_iter_slider, rank_slider, run_cpd_button


@app.cell
def _(build_tensor_data, csv_dir_input, load_all_data, mo, pd):
    try:
        loaded_df = load_all_data(csv_dir_input.value)
        tdt_data = build_tensor_data(loaded_df)
        skipped_warning = loaded_df.attrs.get("skipped_files", [])
    except Exception as data_error:
        mo.stop(True, mo.callout(str(data_error), kind="danger"))

    n_co, n_cr, n_fe, n_T = tdt_data["dims"]
    metrics_df = pd.DataFrame(
        {
            "Quantity": ["Co", "Cr", "Fe", "Temperature", "Valid entries"],
            "Value": [n_co, n_cr, n_fe, n_T, f"{tdt_data['valid_count']:,}"],
        }
    )

    display_blocks = [
        mo.md("## Loaded tensor data"),
        metrics_df,
    ]
    if skipped_warning:
        display_blocks.append(
            mo.callout(
                "Some CSV files were skipped:\n\n" + "\n".join(f"- {item}" for item in skipped_warning),
                kind="warn",
            )
        )
    mo.vstack(display_blocks)
    return loaded_df, metrics_df, n_T, n_co, n_cr, n_fe, skipped_warning, tdt_data


@app.cell
def _(max_iter_slider, mo, rank_slider, run_cpd_button, run_cpd_pair, tdt_data):
    if not run_cpd_button.value:
        mo.stop(
            True,
            mo.md("> Click the run button above to calculate the LIQUID and FCC factor matrices."),
        )

    mo.md("## CPD calculation")
    factor_result = run_cpd_pair(
        tdt_data=tdt_data,
        rank=int(rank_slider.value),
        max_iter=int(max_iter_slider.value),
    )
    factor_result
    return factor_result


@app.cell
def _(factor_result, mo, np):
    status_messages = []
    if not np.isfinite(factor_result["err_liq"]):
        status_messages.append(
            mo.callout(
                "LIQUID RMSE is not finite. This matches the original unregularized CPD-ALS; try reducing rank or max iterations if needed.",
                kind="warn",
            )
        )
    if not np.isfinite(factor_result["err_fcc"]):
        status_messages.append(
            mo.callout(
                "FCC RMSE is not finite. This matches the original unregularized CPD-ALS; try reducing rank or max iterations if needed.",
                kind="warn",
            )
        )

    status_messages.append(
        mo.callout(
            f"LIQUID RMSE = {factor_result['err_liq']:.6g} | "
            f"FCC RMSE = {factor_result['err_fcc']:.6g} "
            "(normalized tensor units; original ALS)",
            kind="success",
        )
    )
    mo.vstack(status_messages)
    return


@app.cell
def _(factor_result, plot_unified_factor_matrices, tdt_data):
    fig_liq = plot_unified_factor_matrices(
        factor_result["A_liq"],
        factor_result["B_liq"],
        factor_result["C_liq"],
        factor_result["D_liq"],
        factor_result["lam_liq"],
        tdt_data["co_vals"],
        tdt_data["cr_vals"],
        tdt_data["fe_vals"],
        tdt_data["T_vals"],
        phase="LIQUID",
        R=factor_result["rank"],
    )
    fig_fcc = plot_unified_factor_matrices(
        factor_result["A_fcc"],
        factor_result["B_fcc"],
        factor_result["C_fcc"],
        factor_result["D_fcc"],
        factor_result["lam_fcc"],
        tdt_data["co_vals"],
        tdt_data["cr_vals"],
        tdt_data["fe_vals"],
        tdt_data["T_vals"],
        phase="FCC",
        R=factor_result["rank"],
    )
    return fig_fcc, fig_liq


@app.cell
def _(
    factor_matrices_to_long_csv,
    factor_matrices_to_wide_csv,
    factor_result,
    pd,
    tdt_data,
):
    liq_csv_df = factor_matrices_to_long_csv(
        factor_result["A_liq"],
        factor_result["B_liq"],
        factor_result["C_liq"],
        factor_result["D_liq"],
        factor_result["lam_liq"],
        tdt_data["co_vals"],
        tdt_data["cr_vals"],
        tdt_data["fe_vals"],
        tdt_data["T_vals"],
        phase="LIQUID",
        R=factor_result["rank"],
    )
    fcc_csv_df = factor_matrices_to_long_csv(
        factor_result["A_fcc"],
        factor_result["B_fcc"],
        factor_result["C_fcc"],
        factor_result["D_fcc"],
        factor_result["lam_fcc"],
        tdt_data["co_vals"],
        tdt_data["cr_vals"],
        tdt_data["fe_vals"],
        tdt_data["T_vals"],
        phase="FCC",
        R=factor_result["rank"],
    )
    combined_csv_df = pd.concat([liq_csv_df, fcc_csv_df], ignore_index=True)
    liq_wide_df = factor_matrices_to_wide_csv(liq_csv_df)
    fcc_wide_df = factor_matrices_to_wide_csv(fcc_csv_df)
    combined_wide_df = factor_matrices_to_wide_csv(combined_csv_df)
    return (
        combined_csv_df,
        combined_wide_df,
        fcc_csv_df,
        fcc_wide_df,
        liq_csv_df,
        liq_wide_df,
    )


@app.cell
def _(
    combined_csv_df,
    combined_wide_df,
    factor_result,
    fcc_csv_df,
    fcc_wide_df,
    liq_csv_df,
    liq_wide_df,
    mo,
):
    R_value = factor_result["rank"]
    downloads = mo.accordion(
        {
            "⬇️ Download plotted factor-matrix data as CSV": mo.vstack(
                [
                    mo.md(
                        "The `plotted_value` column is the exact y-value used in the plots: "
                        "λ·A, λ·B, λ·C, or λ·D. Use the long CSV for Python/Plotly/Origin; "
                        "use the wide CSV if you want one column per component."
                    ),
                    mo.hstack(
                        [
                            mo.vstack(
                                [
                                    mo.download(
                                        data=liq_csv_df.to_csv(index=False),
                                        filename=f"LIQUID_factor_matrices_R{R_value}_long.csv",
                                        mimetype="text/csv",
                                        label="Download LIQUID long CSV",
                                    ),
                                    mo.download(
                                        data=liq_wide_df.to_csv(index=False),
                                        filename=f"LIQUID_factor_matrices_R{R_value}_wide.csv",
                                        mimetype="text/csv",
                                        label="Download LIQUID wide CSV",
                                    ),
                                ]
                            ),
                            mo.vstack(
                                [
                                    mo.download(
                                        data=fcc_csv_df.to_csv(index=False),
                                        filename=f"FCC_factor_matrices_R{R_value}_long.csv",
                                        mimetype="text/csv",
                                        label="Download FCC long CSV",
                                    ),
                                    mo.download(
                                        data=fcc_wide_df.to_csv(index=False),
                                        filename=f"FCC_factor_matrices_R{R_value}_wide.csv",
                                        mimetype="text/csv",
                                        label="Download FCC wide CSV",
                                    ),
                                ]
                            ),
                            mo.vstack(
                                [
                                    mo.download(
                                        data=combined_csv_df.to_csv(index=False),
                                        filename=f"LIQUID_FCC_factor_matrices_R{R_value}_long.csv",
                                        mimetype="text/csv",
                                        label="Download LIQUID + FCC long CSV",
                                    ),
                                    mo.download(
                                        data=combined_wide_df.to_csv(index=False),
                                        filename=f"LIQUID_FCC_factor_matrices_R{R_value}_wide.csv",
                                        mimetype="text/csv",
                                        label="Download LIQUID + FCC wide CSV",
                                    ),
                                ]
                            ),
                        ]
                    ),
                ]
            )
        }
    )
    downloads
    return R_value, downloads


@app.cell
def _(fig_fcc, fig_liq, mo):
    factor_tabs = mo.ui.tabs(
        {
            "LIQUID": fig_liq,
            "FCC": fig_fcc,
            "Side-by-side": mo.hstack(
                [
                    mo.vstack([mo.md("### LIQUID"), fig_liq]),
                    mo.vstack([mo.md("### FCC"), fig_fcc]),
                ]
            ),
        }
    )
    factor_tabs
    return factor_tabs


if __name__ == "__main__":
    app.run()
