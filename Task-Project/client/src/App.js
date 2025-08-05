import React, { useState, useRef, useEffect } from 'react';
import {
  BrowserRouter as Router,
  Routes,
  Route,
  useNavigate
} from 'react-router-dom';
import axios from 'axios';
import {
  FiUploadCloud,
  FiCheckCircle,
  FiAlertCircle,
  FiPackage,
} from 'react-icons/fi';
import './App.css';

function UploadPage() {
  const [selectedFile, setSelectedFile] = useState(null);
  const [previewUrl, setPreviewUrl] = useState('');
  const [message, setMessage] = useState({ text: '', type: '' });
  const [isUploading, setIsUploading] = useState(false);
  const [isDragging, setIsDragging] = useState(false);
  const fileInputRef = useRef(null);
  const navigate = useNavigate();

  const handleFileSelect = (file) => {
    if (file && file.type.startsWith('image/')) {
      setSelectedFile(file);
      setPreviewUrl(URL.createObjectURL(file));
      setMessage({ text: '', type: '' });
    } else {
      setMessage({ text: 'Please select a valid image file.', type: 'error' });
      setSelectedFile(null);
      setPreviewUrl('');
    }
  };

  const handleFileChange = (e) => handleFileSelect(e.target.files[0]);
  const onAreaClick = () => fileInputRef.current.click();
  const handleDragOver = (e) => {
    e.preventDefault();
    setIsDragging(true);
  };
  const handleDragLeave = (e) => {
    e.preventDefault();
    setIsDragging(false);
  };
  const handleDrop = (e) => {
    e.preventDefault();
    setIsDragging(false);
    handleFileSelect(e.dataTransfer.files[0]);
  };
  const handleCancel = () => {
    setSelectedFile(null);
    setPreviewUrl('');
  };

  const handleUpload = async () => {
    if (!selectedFile) {
      setMessage({ text: 'Please select a file first!', type: 'error' });
      return;
    }

    setIsUploading(true);
    setMessage({ text: 'Encrypting and uploading to secure vault...', type: 'info' });

    try {
      const response = await axios.get('http://localhost:3001/api/generate-upload-url', {
        params: {
          fileName: selectedFile.name,
          fileType: selectedFile.type,
        },
      });

      const { uploadUrl } = response.data;

      await axios.put(uploadUrl, selectedFile, {
        headers: {
          'Content-Type': selectedFile.type,
        },
      });

      navigate('/gallery');
    } catch (error) {
      console.error('Upload failed:', error);
      setMessage({ text: 'An error occurred during transmission.', type: 'error' });
    } finally {
      setIsUploading(false);
      setSelectedFile(null);
      setPreviewUrl('');
    }
  };

  return (
    <div className="main-container">
      <div className="aurora-background">
        <div className="aurora-shape shape1"></div>
        <div className="aurora-shape shape2"></div>
        <div className="aurora-shape shape3"></div>
        <div className="aurora-shape shape4"></div>
      </div>

      <div className="upload-card">
        <div className="card-header">
          <FiPackage size={24} />
          <h2>Secure File Transfer</h2>
        </div>
        <p className="subtitle">Upload your assets to our encrypted cloud storage.</p>

        {!previewUrl && !isUploading && (
          <div
            className={`uploader-area ${isDragging ? 'dragging' : ''}`}
            onClick={onAreaClick}
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
            onDrop={handleDrop}
          >
            <input type="file" accept="image/*" onChange={handleFileChange} ref={fileInputRef} hidden />
            <FiUploadCloud className="upload-icon" />
            <p><strong>Click to browse</strong> or drag & drop your file here.</p>
          </div>
        )}

        {previewUrl && !isUploading && (
          <div className="preview-area">
            <img src={previewUrl} alt="Selected preview" className="preview-image" />
            <div className="file-info">
              <span>{selectedFile.name}</span>
              <small>{(selectedFile.size / 1024).toFixed(2)} KB</small>
            </div>
            <div className="preview-actions">
              <button onClick={handleUpload} className="upload-btn">Confirm & Upload</button>
              <button onClick={handleCancel} className="cancel-btn">Cancel</button>
            </div>
          </div>
        )}

        {isUploading && (
          <div className="loading-area">
            <div className="spinner"></div>
            <p>Transmitting securely...</p>
          </div>
        )}

        {message.text && (
          <div className={`message ${message.type}`}>
            {message.type === 'success' && <FiCheckCircle />}
            {message.type === 'error' && <FiAlertCircle />}
            {message.text}
          </div>
        )}
      </div>
    </div>
  );
}

function GalleryPage() {
  const [images, setImages] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchImages = async () => {
      try {
        const response = await axios.get('http://localhost:3001/api/images');
        setImages(response.data);
      } catch (error) {
        console.error("Failed to load images", error);
      } finally {
        setLoading(false);
      }
    };

    fetchImages();
  }, []);

  return (
    <div className="preview-container">
      <div className="aurora-background">
        <div className="aurora-shape shape1"></div>
        <div className="aurora-shape shape2"></div>
        <div className="aurora-shape shape3"></div>
        <div className="aurora-shape shape4"></div>
      </div>

      <div className="preview-card">
        <h2>Uploaded Images</h2>
        {loading ? (
          <p>Loading...</p>
        ) : images.length === 0 ? (
          <p>No images found!</p>
        ) : (
          <div className="gallery-grid">
            {images.map((url, index) => (
              <div key={index} className="gallery-item">
                <img src={url} alt={`uploaded-${index}`} className="preview-image" />
                <a href={url} target="_blank" rel="noopener noreferrer">
                  <button className="btn">Open in New Tab</button>
                </a>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<UploadPage />} />
        <Route path="/gallery" element={<GalleryPage />} />
      </Routes>
    </Router>
  );
}

export default App;
