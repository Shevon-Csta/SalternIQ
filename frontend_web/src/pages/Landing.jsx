import { Link } from 'react-router-dom'
import { ArrowRight } from 'lucide-react'
import './Landing.css'

// ── Section imagery — salt farming and Sri Lanka coastal ──────────
const IMG = {
  hero:     'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?auto=format&fit=crop&w=1920&q=80',
  salterns: 'https://images.unsplash.com/photo-1473116763249-2faaef81ccda?auto=format&fit=crop&w=1200&q=80',
  coast:    'https://images.unsplash.com/photo-1586348943529-beaae6c28db9?auto=format&fit=crop&w=1200&q=80',
  farmer:   'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?auto=format&fit=crop&w=1200&q=80',
  divider1: 'https://images.unsplash.com/photo-1470770841072-f978cf4d019e?auto=format&fit=crop&w=1920&q=80',
  tech:     'https://images.unsplash.com/photo-1551288049-bebda4e38f71?auto=format&fit=crop&w=1200&q=80',
}

export default function Landing() {
  return (
    <div className="lp">

      {/* ── Nav ───────────────────────────────────────────────────── */}
      <nav className="lp-nav">
        <div className="lp-nav-inner">
          <div className="lp-logo">Saltern<span>IQ</span></div>
          <div className="lp-nav-links">
            <a href="#problem">The Problem</a>
            <a href="#how">How It Works</a>
            <a href="#project">The Project</a>
          </div>
          <div className="lp-nav-actions">
            <Link to="/login">Sign in</Link>
            <Link to="/register" className="lp-nav-cta">Get started</Link>
          </div>
        </div>
      </nav>

      {/* ── Hero ──────────────────────────────────────────────────── */}
      <section className="lp-hero" style={{ backgroundImage: `url(${IMG.hero})` }}>
        <div className="lp-hero-overlay" />
        <div className="lp-hero-content">
          <p className="lp-eyebrow">Sri Lanka · Salt Farming · Machine Learning</p>
          <h1>
            Smarter land choices<br />for Sri Lanka's<br />salt farmers.
          </h1>
          <p className="lp-hero-sub">
            SalternIQ predicts whether a coastal site is viable for saltern
            establishment — using climate data, terrain analysis, and two
            trained ML models. Built for the farmers who need it most.
          </p>
          <div className="lp-hero-btns">
            <Link to="/register" className="lp-btn-white">
              Start assessing <ArrowRight size={15} />
            </Link>
            <a href="#problem" className="lp-btn-outline-white">Learn more</a>
          </div>
        </div>
        <div className="lp-hero-scroll">
          <span>Scroll</span>
          <div className="lp-scroll-line" />
        </div>
      </section>

      {/* ── Section 01 — The Problem ──────────────────────────────── */}
      <section className="lp-section" id="problem">
        <div className="lp-container">
          <div className="lp-split" data-reverse="false">
            <div className="lp-split-text">
              <p className="lp-section-num">01</p>
              <h2>Site selection without data costs farmers every season.</h2>
              <p>
                Sri Lanka's salt industry spans state-operated salterns — Hambantota,
                Puttalam, Elephant Pass — and hundreds of small-scale operations
                along coastal lagoons. State farms have environmental assessment
                tools. Small-scale farmers do not.
              </p>
              <p>
                Site selection relies on habit and limited knowledge, with little
                attention to soil salinity, pH, erosion, or climate patterns.
                The result is suboptimal yields and annual losses that fall on
                the farmers least able to absorb them.
              </p>
              <Link to="/register" className="lp-link-arrow">
                Start your first assessment <ArrowRight size={14} />
              </Link>
            </div>
            <div className="lp-split-img">
              <img src={IMG.salterns} alt="Salt evaporation ponds aerial view" />
            </div>
          </div>
        </div>
      </section>

      {/* ── Full-width image break ─────────────────────────────────── */}
      <div className="lp-img-break" style={{ backgroundImage: `url(${IMG.divider1})` }}>
        <div className="lp-img-break-inner">
          <p className="lp-img-break-stat">93%</p>
          <p className="lp-img-break-label">viability classification accuracy</p>
        </div>
      </div>

      {/* ── Section 02 — How It Works ─────────────────────────────── */}
      <section className="lp-section lp-section-alt" id="how">
        <div className="lp-container">
          <div className="lp-split" data-reverse="true">
            <div className="lp-split-img">
              <img src={IMG.coast} alt="Sri Lanka coastline and lagoon" />
            </div>
            <div className="lp-split-text">
              <p className="lp-section-num">02</p>
              <h2>Drop a pin. Get an answer in seconds.</h2>
              <p>
                Click any point on the Sri Lanka coastline. SalternIQ fetches
                historical climate data from open satellite archives — temperature,
                rainfall, wind — then combines it with your site parameters.
              </p>
              <p>
                Two trained models run in under a second: a Random Forest
                classifier for viability, and a Gradient Boosting regressor
                for estimated salt yield in tons. You get a plain-language
                result and specific recommendations.
              </p>
              <div className="lp-steps-inline">
                <div className="lp-step-inline">
                  <span className="lp-step-n">01</span>
                  <span>Select a site on the map or enter parameters manually</span>
                </div>
                <div className="lp-step-inline">
                  <span className="lp-step-n">02</span>
                  <span>Climate data is fetched automatically from Open-Meteo</span>
                </div>
                <div className="lp-step-inline">
                  <span className="lp-step-n">03</span>
                  <span>ML models return viability verdict and yield estimate</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── Section 03 — Technology ───────────────────────────────── */}
      <section className="lp-section">
        <div className="lp-container">
          <div className="lp-split" data-reverse="false">
            <div className="lp-split-text">
              <p className="lp-section-num">03</p>
              <h2>Twelve factors. Two models. One clear verdict.</h2>
              <p>
                Each assessment analyses twelve environmental parameters —
                distance to coast, soil permeability, brine salinity,
                temperature, rainfall, humidity, solar radiation, wind speed,
                and an evaporation index derived from the combined readings.
              </p>
              <p>
                The system runs entirely locally. No cloud dependency, no
                third-party APIs for computation — just a FastAPI backend,
                SQLite database, and scikit-learn models deployed on hardware
                you already own.
              </p>
              <p>
                Built on a FastAPI backend with scikit-learn models, Leaflet
                maps, and the Open-Meteo climate archive. No cloud dependencies —
                everything runs on local hardware.
              </p>
            </div>
            <div className="lp-split-img">
              <img src={IMG.tech} alt="Data analysis and machine learning dashboard" />
            </div>
          </div>
        </div>
      </section>

      {/* ── Section 04 — The Farmer ───────────────────────────────── */}
      <section className="lp-section lp-section-alt">
        <div className="lp-container">
          <div className="lp-split" data-reverse="true">
            <div className="lp-split-img">
              <img src={IMG.farmer} alt="Farmer working in Sri Lankan salt field" />
            </div>
            <div className="lp-split-text">
              <p className="lp-section-num">04</p>
              <h2>Built for the people who know the land, not the algorithm.</h2>
              <p>
                SalternIQ is designed for small-scale salt farmers with no
                data science background. You enter what you know about your
                land — or just click the map — and the system handles the rest.
              </p>
              <p>
                Results include a viability score, an estimated yield, and
                concrete recommendations in plain language: what conditions
                fell short, what to watch for, whether the site is worth a
                closer look.
              </p>
              <p>
                Every assessment is saved to your account, so you can track
                multiple sites over time and compare results across seasons.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* ── Section 05 — About ────────────────────────────────────── */}
      <section className="lp-about-section" id="project">
        <div className="lp-container">
          <div className="lp-about-grid">
            <div className="lp-about-text">
              <p className="lp-section-num">05</p>
              <h2>About the project</h2>
              <p>
                SalternIQ was developed by <strong>Shevon Costa</strong> as a
                Final Year Project for the BEng (Hons) Software Engineering
                programme at the Informatics Institute of Technology (IIT),
                Colombo, in collaboration with the University of Westminster.
              </p>
              <p>
                The project was motivated by a genuine gap in the literature:
                while machine learning has been applied extensively to agricultural
                land suitability, no accessible tool existed for Sri Lanka's
                salt farming community. SalternIQ fills that gap using freely
                available satellite and climate data.
              </p>
              <p className="lp-about-meta">
                Supervised by Mr. Chathura Wickramasinghe · IIT Colombo ·
                University of Westminster · 2025–2026
              </p>
            </div>
            <div className="lp-about-card">
              <div className="lp-about-stat">
                <div className="las-number">12</div>
                <div className="las-label">environmental factors per assessment</div>
              </div>
              <div className="lp-about-stat">
                <div className="las-number">2</div>
                <div className="las-label">ML models — classifier + regressor</div>
              </div>
              <div className="lp-about-stat">
                <div className="las-number">93%</div>
                <div className="las-label">viability prediction accuracy</div>
              </div>
              <div className="lp-about-stat">
                <div className="las-number">0</div>
                <div className="las-label">third-party cloud dependencies</div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── CTA ───────────────────────────────────────────────────── */}
      <section className="lp-cta" style={{ backgroundImage: `url(${IMG.salterns})` }}>
        <div className="lp-cta-overlay" />
        <div className="lp-cta-content">
          <h2>Your land deserves better than guesswork.</h2>
          <p>Create a free account and run your first assessment in under two minutes.</p>
          <Link to="/register" className="lp-btn-white">
            Get started <ArrowRight size={15} />
          </Link>
        </div>
      </section>

      {/* ── Footer ────────────────────────────────────────────────── */}
      <footer className="lp-footer">
        <div className="lp-container">
          <div className="lp-footer-inner">
            <div>
              <div className="lp-logo" style={{ marginBottom: 6 }}>Saltern<span>IQ</span></div>
              <p className="lp-footer-sub">
                BEng Software Engineering Final Year Project<br />
                IIT Colombo · University of Westminster
              </p>
            </div>
            <div className="lp-footer-links">
              <Link to="/login">Sign in</Link>
              <Link to="/register">Register</Link>
              <a href="#problem">About</a>
            </div>
          </div>
          <div className="lp-footer-copy">
            © 2026 Shevon Costa. Built for academic demonstration purposes.
          </div>
        </div>
      </footer>

    </div>
  )
}
