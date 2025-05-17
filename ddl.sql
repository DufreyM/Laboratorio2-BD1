CREATE TABLE Donantes (
    id_donante INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    genero CHAR(1) NOT NULL CHECK (genero IN ('M', 'F', 'O')),
    tipo_sangre VARCHAR(3) NOT NULL CHECK (tipo_sangre IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    telefono VARCHAR(15) UNIQUE,
    correo VARCHAR(100) UNIQUE,
    direccion TEXT
);

CREATE TABLE Organizadores (
    id_organizador INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    nombre VARCHAR(100) NOT NULL,
    tipo VARCHAR(50) NOT NULL CHECK (tipo IN ('Hospital', 'ONG', 'Universidad', 'Empresa', 'Otro')),
    contacto VARCHAR(100) NOT NULL,
    telefono VARCHAR(15),
    correo VARCHAR(100)
);

CREATE TABLE Campañas (
    id_campaña INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    ubicacion VARCHAR(100) NOT NULL,
    id_organizador INT NOT NULL,
    FOREIGN KEY (id_organizador) REFERENCES Organizadores(id_organizador),
    CHECK (fecha_fin >= fecha_inicio)
);

CREATE TABLE Donaciones (
    id_donacion INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    id_donante INT NOT NULL,
    id_campaña INT NOT NULL,
    fecha_donacion DATE NOT NULL,
    cantidad_ml INT NOT NULL CHECK (cantidad_ml > 0 AND cantidad_ml <= 600),
    estado VARCHAR(20) NOT NULL CHECK (estado IN ('Aprobada', 'Rechazada', 'Diferida')),
    FOREIGN KEY (id_donante) REFERENCES Donantes(id_donante),
    FOREIGN KEY (id_campaña) REFERENCES Campañas(id_campaña)
);

CREATE TABLE Citas (
    id_cita INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    id_donante INT NOT NULL,
    id_campaña INT NOT NULL,
    fecha_hora TIMESTAMP NOT NULL,
    estado VARCHAR(20) NOT NULL CHECK (estado IN ('Confirmada', 'Cancelada', 'Atendida')),
    FOREIGN KEY (id_donante) REFERENCES Donantes(id_donante),
    FOREIGN KEY (id_campaña) REFERENCES Campañas(id_campaña)
);

CREATE TABLE Historial_Medico (
    id_historial INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    id_donante INT NOT NULL,
    fecha_evaluacion DATE NOT NULL,
    presion_arterial VARCHAR(20),
    nivel_hemoglobina DECIMAL(4,2),
    peso DECIMAL(5,2) CHECK (peso > 0),
    resultado VARCHAR(10) NOT NULL CHECK (resultado IN ('Apto', 'No Apto')),
    FOREIGN KEY (id_donante) REFERENCES Donantes(id_donante)
);

CREATE TABLE Personal_Medico (
    id_personal INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    nombre VARCHAR(100) NOT NULL,
    cargo VARCHAR(50) NOT NULL CHECK (cargo IN ('Médico', 'Enfermero', 'Técnico', 'Otro')),
    correo VARCHAR(100) UNIQUE,
    telefono VARCHAR(50)
);

CREATE TABLE Evaluaciones (
    id_evaluacion INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    id_donacion INT NOT NULL,
    id_personal INT NOT NULL,
    observaciones TEXT,
    resultado VARCHAR(20) NOT NULL CHECK (resultado IN ('Exitosa', 'Fallida', 'Complicada')),
    FOREIGN KEY (id_donacion) REFERENCES Donaciones(id_donacion),
    FOREIGN KEY (id_personal) REFERENCES Personal_Medico(id_personal)
);
